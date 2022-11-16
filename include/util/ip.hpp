#ifndef UTIL_IP_HPP
#define UTIL_IP_HPP

extern "C" {
#include <arpa/inet.h>  // inet_pton
#include <netinet/in.h> // sockaddr_in
}

namespace util {
namespace ip {

static
in_addr_t
address_from_string(char const *ip_str)
noexcept {
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
make_sockaddr_in(in_addr_t address, u16 port)
noexcept {
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
noexcept {
  static char ipbuf[INET_ADDRSTRLEN + 1];
  assert_nonzero(inet_ntop(AF_INET, &addr.sin_addr, static_cast<char*>(ipbuf), INET_ADDRSTRLEN), "inet_ntop failed");
  ipbuf[INET_ADDRSTRLEN] = '\0';
  try {
    return std::string{static_cast<char*>(ipbuf)} + ':' + std::to_string(ntohs(addr.sin_port));
  } catch (std::exception const &e) {
    try { return "[couldn't stringify IP/port: " + std::string{e.what()} + ']'; } catch (...) { std::terminate(); }
  } catch (...) { std::terminate(); }
}

} // namespace ip
} // namespace util

#endif // UTIL_IP_HPP
