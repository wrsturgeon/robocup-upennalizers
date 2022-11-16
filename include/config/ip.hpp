#ifndef CONFIG_IP_HPP
#define CONFIG_IP_HPP

#include "util/ip.hpp"

#include "config/gamecontroller.hpp"

extern "C" {
#include <sys/types.h> // in_addr_t
}

#include <string>

namespace config {
namespace ip {

//%%%%%%%%%%%%%%%% Type declarations

template <util::FixedString DeviceName>
impure static
in_addr_t // no reason for a const reference; typedef'd to an int anyway, smaller than a pointer
address()
noexcept {
  std::cerr << "No IP address registered for \"" << DeviceName << "\"\n";
  std::terminate();
}

template <util::FixedString DeviceName>
struct port {
  impure static u16 from() noexcept;
  impure static u16 to() noexcept;
};

//%%%%%%%%%%%%%%%% Registering devices

// GameController
template <> impure u16 port<"GameController">::from() noexcept { return GAMECONTROLLER_DATA_PORT; }
template <> impure u16 port<"GameController">::to() noexcept { return GAMECONTROLLER_RETURN_PORT; }
template <>
impure
in_addr_t
address<"GameController">()
noexcept {
  static in_addr_t const addr{util::ip::address_from_string(file::contents<"include/config/runtime/gamecontroller.ip">())};
  return addr;
}
#undef GAMECONTROLLER_DATA_PORT
#undef GAMECONTROLLER_RETURN_PORT

// Local
template <> impure u16 port<"Local">::from() noexcept {
  static u16 const val{static_cast<u16>(10000 + config::gamecontroller::team::upenn_number())};
  return val;
}
template <> impure u16 port<"Local">::to() noexcept { return port<"Local">::from(); } // for now
template <>
impure
in_addr_t
address<"local">()
noexcept {
  static std::string const str{[]{
    try {
      return "10.0." + std::to_string(config::gamecontroller::team::upenn_number()) + '.' + std::to_string(config::player::number);
    } catch (...) { std::terminate(); }
  }()};
  static in_addr_t const addr{util::ip::address_from_string(str.c_str())};
  return addr;
}

} // namespace ip
} // namespace config

#endif // CONFIG_IP_HPP
