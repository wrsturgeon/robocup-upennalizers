#ifndef UTIL_IP_HPP
#define UTIL_IP_HPP

#include <algorithm>    // std::fill_n

#if DEBUG
#include <string>       // std::string
#endif // DEBUG

extern "C" {
#include <arpa/inet.h>  // inet_pton
#include <netinet/in.h> // sockaddr_in
#include <sys/types.h>  // in_addr_t
}

namespace util {
namespace ip {

static
in_addr_t
address_from_string(char const *ip_str)
noexcept {
  sockaddr_in s_in{uninitialized<sockaddr_in>()};
  assert_eq(0, inet_pton(AF_INET, ip_str, &s_in.sin_addr) - 1, "Invalid IP address")
  return s_in.sin_addr.s_addr;
}

static
sockaddr_in
make_sockaddr_in(in_addr_t address, u16 port)
noexcept {
  sockaddr_in addr{uninitialized<sockaddr_in>()};
  std::fill_n(reinterpret_cast<char*>(&addr), sizeof addr, '\0');
  addr.sin_family = AF_INET;
  addr.sin_addr.s_addr = address;
  addr.sin_port = htons(port);
  return addr;
}

} // namespace ip
} // namespace util

#endif // UTIL_IP_HPP
