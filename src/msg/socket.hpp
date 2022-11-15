#pragma once

#include "config/wireless.hpp"

extern "C" {
#include <arpa/inet.h> // inet_pton
#include <netinet/in.h> // sockaddr_in
#include <sys/socket.h> // socket
#include <sys/types.h> // in_addr_t
#include <unistd.h> // close
}

#include <algorithm>   // std::fill_n
#include <cerrno>      // errno
#include <cstddef>     // std::ssize_t
#include <iostream>    // std::cerr
#include <type_traits> // std::decay_t

namespace msg {

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wweak-vtables"
class error : public std::runtime_error { using std::runtime_error::runtime_error; };
#pragma clang diagnostic pop

enum direction {
  incoming,
  outgoing,
};

enum mode {
  unicast,
  broadcast,
};

static auto
address_from_ip(char const *ip_str) noexcept
-> in_addr_t {
  auto s_in = uninitialized<sockaddr_in>();
  if (inet_pton(AF_INET, ip_str, &s_in.sin_addr) != 1) {
    std::cerr << "Invalid IP address (\"" << ip_str << "\"): " << strerror(errno) << " (errno " << errno << ")\n";
    std::terminate();
  }
  return s_in.sin_addr.s_addr;
}

static auto
make_sockaddr_in(in_addr_t address, u16 port) noexcept
-> sockaddr_in {
  auto addr = uninitialized<sockaddr_in>();
  std::fill_n(reinterpret_cast<char*>(&addr), sizeof addr, '\0');
  addr.sin_family = AF_INET;
  addr.sin_addr.s_addr = address; // htonl(address);
  addr.sin_port = htons(port);
  return addr;
}

template <direction D, mode M>
class Socket {
  using fd_t = decltype(socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP));
  fd_t const socketfd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
  sockaddr_in const addr;
 public:
  Socket(in_addr_t address, u16 port) noexcept;
  Socket(Socket const&) = delete;
  Socket(Socket&&) = delete;
  auto operator=(Socket const&) -> Socket& = delete;
  auto operator=(Socket&&) -> Socket& = delete;
  ~Socket() noexcept { ASSERT_ZERO(close(socketfd)); }
  template <typename T> auto send(T&& data) const -> void requires ((D == direction::outgoing) and not std::is_pointer_v<T>);
  template <typename T> auto recv() const -> std::decay_t<T> requires ((D == direction::incoming) and not std::is_pointer_v<T>);
};

template <direction D, mode M>
Socket<D, M>::Socket(in_addr_t address, u16 port) noexcept
    : addr{make_sockaddr_in(address, port)}
{
  if (socketfd < 0) {
    std::cerr << "socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP) returned " << socketfd << ": " << strerror(errno) << " (errno " << errno << ")\n";
    std::terminate();
  }
  constexpr auto bcast_opt = int{M == mode::broadcast};
  setsockopt(socketfd, SOL_SOCKET, SO_BROADCAST, &bcast_opt, sizeof bcast_opt);
  setsockopt(socketfd, SOL_SOCKET, SO_REUSEADDR, &addr, sizeof addr);
  setsockopt(socketfd, SOL_SOCKET, SO_REUSEPORT, &addr, sizeof addr);
  int r;
  if constexpr (D == direction::outgoing) {
    r = connect(socketfd, reinterpret_cast<sockaddr const*>(&addr), sizeof addr);
  } else {
    auto from_addr = make_sockaddr_in(INADDR_ANY, port);
    r = bind(socketfd, reinterpret_cast<sockaddr const*>(&from_addr), sizeof from_addr);
  }
  if (r) {
    std::cerr << (
          (D == direction::outgoing) ? "connect" : "bind")
       << "(socket_fd = " << socketfd
       << ", &addr = &(" << inet_ntoa(addr.sin_addr) << ':' << ntohs(addr.sin_port)
       << "), sizeof addr = " << sizeof addr
       << "B) returned " << r
       << ": " << strerror(errno)
       << " (errno " << errno << ")\n";
    std::terminate();
  }
#if VERBOSE
  std::cout << "Opened an " << ((D == direction::outgoing) ? "outgoing" : "incoming") << ' ' << ((M == mode::broadcast) ? "broadcast" : "unicast") << " socket " << ((D == direction::incoming) ? "from" : "to") << ' ' << inet_ntoa(addr.sin_addr) << ':' << ntohs(addr.sin_port) << std::endl;
#endif // VERBOSE
}

template <direction D, mode M>
template <typename T>
/* NOT inline */ auto
Socket<D, M>::send(T&& data) const -> void requires ((D == direction::outgoing) and not std::is_pointer_v<T>) {
  auto const r = ::send(socketfd, &data, sizeof data, 0);
  if (r != sizeof data) {
    throw ::msg::error{
          "send(socket_fd = " + std::to_string(socketfd)
        + ", &data = ..., sizeof data = " + std::to_string(sizeof data)
        + "B, 0) returned " + std::to_string(r)
        + ": " + strerror(errno)
        + " (errno " + std::to_string(errno) + ')'
    };
  }
}

template <direction D, mode M>
template <typename T>
/* NOT inline */ auto
Socket<D, M>::recv() const -> std::decay_t<T> requires ((D == direction::incoming) and not std::is_pointer_v<T>) {
  auto data = uninitialized<std::decay_t<T>>();
  auto src = uninitialized<sockaddr_in>();
  auto src_len = uninitialized<socklen_t>();
  auto r = uninitialized<decltype(recvfrom(socketfd, &data, sizeof data, 0, reinterpret_cast<sockaddr*>(&src), &src_len))>();
#if defined(PERSNICKETY_IP) && PERSNICKETY_IP
  do { // repeat until we get a message from our expected source
#endif // PERSNICKETY_IP
    r = recvfrom(socketfd, &data, sizeof data, 0, reinterpret_cast<sockaddr*>(&src), &src_len);
#if defined(PERSNICKETY_IP) && PERSNICKETY_IP
#if VERBOSE
    if (src.sin_addr.s_addr != addr.sin_addr.s_addr) {
      std::cout << "Received a message from " << inet_ntoa(src.sin_addr) << ':' << ntohs(src.sin_port) << " instead of " << inet_ntoa(addr.sin_addr) << ':' << ntohs(addr.sin_port) << std::endl;
    }
#endif // VERBOSE
  } while (src.sin_addr.s_addr != addr.sin_addr.s_addr);
#endif // PERSNICKETY_IP
  if (r != sizeof data) {
    throw ::msg::error{
          "recvfrom(socket_fd = " + std::to_string(socketfd)
        + ", &data = ..., sizeof data = " + std::to_string(sizeof data)
        + "B, 0, &src = &(" + inet_ntoa(src.sin_addr) + ':' + std::to_string(ntohs(src.sin_port))
        + "), &src_len = &(" + std::to_string(src_len)
        + ")) returned " + std::to_string(r)
        + ": " + strerror(errno)
        + " (errno " + std::to_string(errno) + ')'
    };
  }
  return data;
}

} // namespace msg
