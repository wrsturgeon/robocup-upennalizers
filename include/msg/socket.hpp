#ifndef MSG_SOCKET_HPP
#define MSG_SOCKET_HPP

#include "config/wireless.hpp"

#include "util/stringify.hpp"

extern "C" {
#include <arpa/inet.h>  // inet_pton
#include <netinet/in.h> // sockaddr_in
#include <sys/socket.h> // socket
#include <sys/types.h>  // in_addr_t
#include <unistd.h>     // close
}

#include <algorithm>   // std::fill_n
#include <cerrno>      // errno
#include <cstddef>     // std::ssize_t
#include <iostream>    // std::cerr
#include <string>      // std::string
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

static
in_addr_t
address_from_ip(char const *ip_str) noexcept
{
  sockaddr_in s_in{uninitialized<sockaddr_in>()};
  if (inet_pton(AF_INET, ip_str, &s_in.sin_addr) != 1) {
    char buf[256];
    get_system_error_message(buf);
    try { std::cerr << "Invalid IP address \"" << ip_str << "\" (errno " << errno << ": " << static_cast<char*>(buf) << ")\n"; } catch (...) {/* std::terminate below */}
    std::terminate();
  }
  return s_in.sin_addr.s_addr;
}

static
sockaddr_in
make_sockaddr_in(in_addr_t address, u16 port) noexcept
{
  sockaddr_in addr{uninitialized<sockaddr_in>()};
  std::fill_n(reinterpret_cast<char*>(&addr), sizeof addr, '\0');
  addr.sin_family = AF_INET;
  addr.sin_addr.s_addr = address;
  addr.sin_port = htons(port);
  return addr;
}

static
std::string
get_ip_port_str(sockaddr_in const &addr)
{
  static char ipbuf[INET_ADDRSTRLEN + 1];
  assert_nonzero(inet_ntop(AF_INET, &addr.sin_addr, static_cast<char*>(ipbuf), INET_ADDRSTRLEN), "inet_ntop failed");
  ipbuf[INET_ADDRSTRLEN] = '\0';
  try {
    return std::string{static_cast<char*>(ipbuf)} + ':' + std::to_string(ntohs(addr.sin_port));
  } catch (std::exception const &e) {
    return "[couldn't stringify IP/port: " + std::string{e.what()} + ']';
  } catch (...) { try { return "[couldn't stringify IP/port or print why]"; } catch (...) { std::terminate(); } }
}

#define OPEN_UDP_SOCKET socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)

template <direction D, mode M>
class Socket
{
  using fd_t = decltype(OPEN_UDP_SOCKET);
  fd_t const socketfd{OPEN_UDP_SOCKET};
  sockaddr_in const addr;
 public:
  Socket(in_addr_t address, u16 port) noexcept;
  Socket(Socket const&) = delete;
  Socket(Socket&&) = delete;
  Socket& operator=(Socket const&) = delete;
  Socket& operator=(Socket&&) = delete;
  ~Socket() noexcept { assert_zero(close(socketfd), "Couldn't close a socket"); }
  template <typename T> void send(T&& data) const;
  template <typename T> std::decay_t<T> recv() const;
};

template <direction D, mode M>
Socket<D, M>::Socket(in_addr_t address, u16 port) noexcept
: addr{make_sockaddr_in(address, port)}
{
  if (socketfd < 0) {
    char buf[256];
    get_system_error_message(buf);
    try { std::cerr << STRINGIFY(OPEN_UDP_SOCKET) " returned " << socketfd << " (errno " << errno << ": " << static_cast<char*>(buf) << ")\n"; } catch (...) {/* std::terminate below */}
    std::terminate();
  }
  constexpr int bcast_opt{M == mode::broadcast};
  setsockopt(socketfd, SOL_SOCKET, SO_BROADCAST, &bcast_opt, sizeof bcast_opt);
  setsockopt(socketfd, SOL_SOCKET, SO_REUSEADDR, &addr, sizeof addr);
  setsockopt(socketfd, SOL_SOCKET, SO_REUSEPORT, &addr, sizeof addr);
  int r; // NOLINT(cppcoreguidelines-init-variables)
  if constexpr (D == direction::outgoing) {
    r = connect(socketfd, reinterpret_cast<sockaddr const*>(&addr), sizeof addr);
  } else {
    sockaddr_in from_addr{make_sockaddr_in(INADDR_ANY, port)};
    r = bind(socketfd, reinterpret_cast<sockaddr const*>(&from_addr), sizeof from_addr);
  }
  if (r) {
    char buf[256];
    get_system_error_message(buf);
    try { std::cerr << (
          (D == direction::outgoing) ? "connect" : "bind")
       << "(socket_fd = " << socketfd
       << ", &addr = &(" << get_ip_port_str(addr)
       << "), sizeof addr = " << sizeof addr
       << "B) returned " << r
       << " (errno " << errno
       << ": " << static_cast<char*>(buf) << ")\n";
    } catch (...) {}
    std::terminate();
  }
#if VERBOSE
  std::cout << "Opened an " << ((D == direction::outgoing) ? "outgoing" : "incoming") << ' ' << ((M == mode::broadcast) ? "broadcast" : "unicast") << " socket " << ((D == direction::incoming) ? "from" : "to") << ' ' << get_ip_port_str(addr) << std::endl;
#endif // VERBOSE
}

#undef OPEN_UDP_SOCKET

template <direction D, mode M>
template <typename T>
// NOT inline
void
Socket<D, M>::send(T&& data) const
{
  static_assert(D == direction::outgoing);
  static_assert(not std::is_pointer_v<T>);
  static_assert(std::is_trivially_copyable_v<T>);
#define SEND_OP ::send(socketfd, &data, sizeof data, 0)
  decltype(SEND_OP) const r{SEND_OP};
  if (r != sizeof data) {
    char buf[256];
    get_system_error_message(buf);
    throw ::msg::error{
          "send(socket_fd = " + std::to_string(socketfd)
        + ", &data = ..., sizeof data = " + std::to_string(sizeof data)
        + "B, 0) returned " + std::to_string(r)
        + " (errno " + std::to_string(errno)
        + ": " + std::string{static_cast<char*>(buf)} + ')'
    };
  }
}

template <direction D, mode M>
template <typename T>
// NOT inline
std::decay_t<T>
Socket<D, M>::recv() const
{
  static_assert(D == direction::incoming);
  static_assert(not std::is_pointer_v<T>);
  static_assert(std::is_trivially_copyable_v<T>);
  std::decay_t<T> data{uninitialized<std::decay_t<T>>()};
  sockaddr_in src{uninitialized<sockaddr_in>()};
  socklen_t src_len{uninitialized<socklen_t>()};
#define RECV_OP recvfrom(socketfd, &data, sizeof data, 0, reinterpret_cast<sockaddr*>(&src), &src_len)
  using rtn_t = decltype(RECV_OP);
  rtn_t r;
#if defined(PERSNICKETY_IP) && PERSNICKETY_IP
  do { // repeat until we get a message from our expected source
#endif // PERSNICKETY_IP
    r = RECV_OP;
#if defined(PERSNICKETY_IP) && PERSNICKETY_IP
#if VERBOSE
    if (src.sin_addr.s_addr != addr.sin_addr.s_addr) {
      std::cout << "Received a message from " << get_ip_port_str(addr) << " instead of " << get_ip_port_str(addr) << std::endl;
    }
#endif // VERBOSE
  } while (src.sin_addr.s_addr != addr.sin_addr.s_addr);
#endif // PERSNICKETY_IP
  if (r != sizeof data) {
    char buf[256];
    get_system_error_message(buf);
    throw ::msg::error{
          "recvfrom(socket_fd = " + std::to_string(socketfd)
        + ", &data = ..., sizeof data = " + std::to_string(sizeof data)
        + "B, 0, &src = &(" + get_ip_port_str(addr)
        + "), &src_len = &(" + std::to_string(src_len)
        + ")) returned " + std::to_string(r)
        + " (errno " + std::to_string(errno)
        + ": " + std::string{static_cast<char*>(buf)} + ')'
    };
  }
  return data;
}

} // namespace msg

#endif // MSG_SOCKET_HPP