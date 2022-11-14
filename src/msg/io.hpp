#pragma once

// See legacy/Lib/Platform/NaoV4/GameControl/lua_GameControlReceiver.cc

#include "config/gamecontroller.hpp"
#include "config/spl-message.hpp"
#include "config/wireless.hpp"

extern "C" {
#include <arpa/inet.h>
#include <errno.h>
#include <fcntl.h>
#include <netdb.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>
}

#include <atomic>    // std::atomic
#include <cassert>   // assert
#include <cstddef>   // std::size_t
#include <fstream>   // std::ifstream (to read config/runtime/gamecontroller.ip)
#include <iostream>  // std::cout
#include <stdexcept> // std::runtime_error
#include <string>    // std::to_string

namespace msg {

namespace internal {

pure static auto
address_from_ip(char const *ip_str)
-> in_addr_t {
  auto sin = uninitialized<sockaddr_in>();
  if (inet_pton(AF_INET, ip_str, &sin.sin_addr) != 1) {
    throw std::runtime_error{"Invalid IP address (\"" + std::string{ip_str} + "\"): " + strerror(errno) + " (errno " + std::to_string(errno) + ')'};
  }
  return sin.sin_addr.s_addr;
}

impure static auto
make_sockaddr_in(in_addr_t address, u16 port) noexcept
-> sockaddr_in {
  auto addr = uninitialized<sockaddr_in>();
  std::fill_n(reinterpret_cast<char*>(&addr), sizeof addr, '\0');
  addr.sin_family = AF_INET;
  addr.sin_addr.s_addr = address; // htonl(address);
  addr.sin_port = htons(port);
  return addr;
}

struct SocketFromGC {
#if DEBUG
  static std::atomic<bool> first_instance;
#endif
  decltype(socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) const socket_fd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
  sockaddr_in const local = make_sockaddr_in(INADDR_ANY, config::udp::gamecontroller::send::port);
  SocketFromGC();
  SocketFromGC(SocketFromGC const&) = delete;
  SocketFromGC(SocketFromGC&&) = delete;
  auto operator=(SocketFromGC const&) -> SocketFromGC& = delete;
  auto operator=(SocketFromGC&&) -> SocketFromGC& = delete;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-variable" // from the assert statement below
  ~SocketFromGC() noexcept { auto const r = close(socket_fd); assert(!r); }
#pragma clang diagnostic pop
};

struct SocketToGC {
#if DEBUG
  static std::atomic<bool> first_instance;
#endif
  decltype(socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)) const socket_fd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
  std::string gc_ip{[]{ std::string s; std::ifstream f{"../config/runtime/gamecontroller.ip"}; if (!f) { std::cerr << "Couldn't open ../config/runtime/gamecontroller.ip\n"; std::exit(1); } f >> s; return s; }()};
  in_addr_t const gc_address = address_from_ip(gc_ip.c_str());
  sockaddr_in const remote = make_sockaddr_in(gc_address, config::udp::gamecontroller::recv::port);
  SocketToGC();
  SocketToGC(SocketToGC const&) = delete;
  SocketToGC(SocketToGC&&) = delete;
  auto operator=(SocketToGC const&) -> SocketToGC& = delete;
  auto operator=(SocketToGC&&) -> SocketToGC& = delete;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-variable" // from the assert statement below
  ~SocketToGC() noexcept { auto const r = close(socket_fd); assert(!r); }
#pragma clang diagnostic pop
};

#if DEBUG
std::atomic<bool> SocketFromGC::first_instance = true;
std::atomic<bool> SocketToGC::first_instance = true;
#endif

SocketFromGC::SocketFromGC() {
#if DEBUG
  assert(first_instance.exchange(false)); // exactly one SocketFromGC per game
#endif
  if (socket_fd < 0) { throw std::runtime_error{"socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP) returned " + std::to_string(socket_fd) + ": " + strerror(errno) + " (errno " + std::to_string(errno) + ')'}; }
  setsockopt(socket_fd, SOL_SOCKET, SO_REUSEADDR, &local, sizeof local);
  setsockopt(socket_fd, SOL_SOCKET, SO_REUSEPORT, &local, sizeof local);
  auto r = bind(socket_fd, reinterpret_cast<sockaddr const*>(&local), sizeof local);
  if (r < 0) {
    throw std::runtime_error{"bind(socket_fd = " + std::to_string(socket_fd) + ", &local = &(" + inet_ntoa(local.sin_addr) + ':' + std::to_string(ntohs(local.sin_port)) + "), sizeof local = " + std::to_string(sizeof local) + "B) returned " + std::to_string(r) + ": " + strerror(errno) + " (errno " + std::to_string(errno) + ')'};
  }
}

SocketToGC::SocketToGC() {
#if DEBUG
  assert(first_instance.exchange(false)); // exactly one SocketToGC per game
#endif
  if (socket_fd < 0) { throw std::runtime_error{"socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP) returned " + std::to_string(socket_fd) + ": " + strerror(errno) + " (errno " + std::to_string(errno) + ')'}; }
  setsockopt(socket_fd, SOL_SOCKET, SO_REUSEADDR, &remote, sizeof remote);
  setsockopt(socket_fd, SOL_SOCKET, SO_REUSEPORT, &remote, sizeof remote);
  auto r = connect(socket_fd, reinterpret_cast<sockaddr const*>(&remote), sizeof remote);
  if (r < 0) { throw std::runtime_error{"connect(socket_fd = " + std::to_string(socket_fd) + ", &remote = &(" + inet_ntoa(remote.sin_addr) + ':' + std::to_string(ntohs(remote.sin_port)) + "), sizeof remote = " + std::to_string(sizeof remote) + "B) returned " + std::to_string(r) + ": " + strerror(errno) + " (errno " + std::to_string(errno) + ')'}; }
}

} // namespace internal

static auto
recv_from_gc()
-> spl::GameControlData {
  static auto s = internal::SocketFromGC{};
  auto src = uninitialized<sockaddr_in>();
  auto src_len = uninitialized<socklen_t>();
  char raw[sizeof(spl::GameControlData)];
  auto* const msg = reinterpret_cast<spl::GameControlData*>(raw);
  auto const n = recvfrom(s.socket_fd, msg, sizeof raw, 0, reinterpret_cast<sockaddr*>(&src), &src_len);
// #if VERBOSE
//   if (n >= 0) {
//     std::cout << "Received " << n << "B from " << inet_ntoa(src.sin_addr) << ':' << ntohs(src.sin_port) << std::endl;
//   }
// #endif
  // TODO: if (n > sizeof msg) ...
  if (n == sizeof raw) { return *msg; }
  throw std::runtime_error{"recvfrom(s.socket_fd = " + std::to_string(s.socket_fd) + ", &msg = ..., sizeof msg = " + std::to_string(sizeof msg) + "B, 0, &src, &src_len) returned " + std::to_string(n) + ": " + strerror(errno) + " (errno " + std::to_string(errno) + ')'};
}

static auto
send_to_gc()
-> void {
  static auto s = internal::SocketToGC{};
// #if VERBOSE
//   std::cout << "Sending to GameController...\n";
// #endif
  auto const msg = ctx::make_gc_message();
  auto const n = send(s.socket_fd, &msg, sizeof msg, 0);
  if (n != sizeof msg) {
    std::cerr << "  Unsuccessful attempt to send to " << inet_ntoa(s.remote.sin_addr) << ':' << ntohs(s.remote.sin_port) << " (" << n << "B actually sent instead of " << sizeof msg << ")\n";
  } else {
// #if VERBOSE
//   if (n >= 0) {
//     std::cout << "  Sent " << msg << " (" << n << "B) to " << inet_ntoa(s.remote.sin_addr) << ':' << ntohs(s.remote.sin_port) << std::endl;
//   } else
// #endif
    throw std::runtime_error{"sendto(s.socket_fd = " + std::to_string(s.socket_fd) + ", &msg = ..., sizeof msg = " + std::to_string(sizeof msg) + "B, 0, &s.remote = &(" + inet_ntoa(s.remote.sin_addr) + ':' + std::to_string(ntohs(s.remote.sin_port)) + "), sizeof s.remote = " + std::to_string(sizeof s.remote) + "B) returned " + std::to_string(n) + ": " + strerror(errno) + " (errno " + std::to_string(errno) + ')'};
  }
}

} // namespace msg
