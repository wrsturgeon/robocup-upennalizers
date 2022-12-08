#ifndef MESSAGING_SOCKET_HPP
#define MESSAGING_SOCKET_HPP

#include "util/ip.hpp"   // for util::ip::make_sockaddr_in

extern "C" {
#include <fcntl.h>       // for fcntl, F_SETFL, O_NONBLOCK
#include <netinet/in.h>  // for sockaddr_in, in_addr_t, INADDR_ANY, IPPROTO_UDP
#include <sys/socket.h>  // for setsockopt, socket, SOL_SOCKET, bind, connect, recvfrom, send, sockaddr, socklen_t, AF_INET, SOCK_DGRAM, SO_BROADCAST, SO_REUSEADDR, SO_REUSEPORT
#include <unistd.h>      // for close
}

#include <optional>      // for std::optional, std::make_optional, std::nullopt
#include <type_traits>   // for std::decay_t

namespace msg {

enum direction {
  incoming,
  outgoing,
};

enum mode {
  unicast,
  broadcast,
};

#define OPEN_UDP_SOCKET 

template <direction D, mode M>
class Socket {
  int const _fd{::socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)};
  sockaddr_in const _addr;
 public:
  Socket(in_addr_t address, u16 port) noexcept;
  Socket(Socket const&) = delete;
  Socket(Socket&&) = delete;
  Socket& operator=(Socket const&) = delete;
  Socket& operator=(Socket&&) = delete;
  ~Socket() noexcept { assert_eq(0, close(_fd), "Couldn't close a socket") }
  template <typename T> [[nodiscard]] bool send(T&& data) const;
  template <typename T> std::optional<std::decay_t<T>> recv() const;
};

template <direction D, mode M>
Socket<D, M>::Socket(in_addr_t address, u16 port) noexcept
: _addr{util::ip::make_sockaddr_in(address, port)} {
  assert_nonneg(_fd, "Couldn't open a socket")
  assert_eq(0, fcntl(_fd, F_SETFL, O_NONBLOCK), "Couldn't set socket to non-blocking") // NOLINT(cppcoreguidelines-pro-type-vararg)
  constexpr int bcast_opt{M == mode::broadcast};
  setsockopt(_fd, SOL_SOCKET, SO_BROADCAST, &bcast_opt, sizeof bcast_opt);
  setsockopt(_fd, SOL_SOCKET, SO_REUSEADDR, &_addr, sizeof _addr);
  setsockopt(_fd, SOL_SOCKET, SO_REUSEPORT, &_addr, sizeof _addr);
  int r; // NOLINT(cppcoreguidelines-init-variables)
  if constexpr (D == direction::outgoing) {
    r = connect(_fd, reinterpret_cast<sockaddr const*>(&_addr), sizeof _addr);
  } else {
    sockaddr_in from_addr{util::ip::make_sockaddr_in(INADDR_ANY, port)};
    r = bind(_fd, reinterpret_cast<sockaddr const*>(&from_addr), sizeof from_addr);
  }
  assert_eq(0, r, (D == direction::outgoing) ? "connect" : "bind")
  // if (r) {
  //   char buf[256];
  //   get_system_error_message(buf);
  //   try { std::cerr << (
  //         (D == direction::outgoing) ? "connect" : "bind")
  //      << "(socket_fd = " << _fd
  //      << ", &_addr = &(" << util::ip::get_ip_port_str(_addr)
  //      << "), sizeof _addr = " << sizeof _addr
  //      << "B) returned " << r
  //      << " (errno " << errno
  //      << ": " << static_cast<char*>(buf) << ")\n";
  //   } catch (...) {}
  //   std::terminate();
  // }
}

#undef OPEN_UDP_SOCKET

template <direction D, mode M>
template <typename T>
// NOT inline
[[nodiscard]] bool
Socket<D, M>::
send(T&& data)
const {
  static_assert(D == direction::outgoing);
  static_assert(not std::is_pointer_v<T>);
  static_assert(std::is_trivially_copyable_v<T>);
  auto const r = ::send(_fd, &data, sizeof data, 0);
  return (r == sizeof data);
}

template <direction D, mode M>
template <typename T>
// NOT inline
std::optional<std::decay_t<T>>
Socket<D, M>::
recv()
const {
  static_assert(D == direction::incoming);
  static_assert(not std::is_pointer_v<T>);
  static_assert(std::is_trivially_copyable_v<T>);
  std::decay_t<T> data{uninitialized<std::decay_t<T>>()}; // NOLINT(cppcoreguidelines-init-variables)
  sockaddr_in src{uninitialized<sockaddr_in>()};
  socklen_t src_len{uninitialized<socklen_t>()};
  auto const r = ::recvfrom(_fd, &data, sizeof data, 0, reinterpret_cast<sockaddr*>(&src), &src_len);
  return (r == sizeof data) ? std::make_optional(data) : std::nullopt;
}

} // namespace msg

#endif // MESSAGING_SOCKET_HPP
