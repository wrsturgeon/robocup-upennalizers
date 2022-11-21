#ifndef CONFIG_IP_HPP
#define CONFIG_IP_HPP

#include "config/gamecontroller.hpp"

#include "util/fixed-string.hpp"
#include "util/ip.hpp"

#include <concepts> // std::same_as

namespace config {
namespace ip {

//%%%%%%%%%%%%%%%% Internal wrappers to enforce type consistency and compile-time errors
// The basic idea is to start with an empty templated struct that we never use outside this file
//   For each valid template argument, we overwrite it with a specialization that has a member `value`
//   Then in the user-facing code (wherever we actually want the value), take the value of `struct<WhateverArgWePassed>::value`
//     If we pass an invalid template argument we get a compile-time error since there's no member `value`
//   And, plus, we can never have inconsistent types or half-assery across different devices since it's all the same code
namespace internal {
template <util::FixedString Device> struct address {};
namespace port {
template <util::FixedString Device> struct from {};
template <util::FixedString Device> struct to {};
} // namespace port
} // namespace internal

template <util::FixedString Device> concept registered = 
  requires { { internal::address<Device>::value.c_str() } -> std::same_as<char const*>; } and // util::FixedString or std::string
  requires { { internal::port::from<Device>::value } -> std::same_as<u16 const&>; } and
  requires { { internal::port::to<Device>::value } -> std::same_as<u16 const&>; };

//%%%%%%%%%%%%%%%% Manually registering devices

// GameController
template <> struct internal::port::from<"GameController">{ static constexpr u16 value{GAMECONTROLLER_DATA_PORT}; };
template <> struct internal::port::to<"GameController">{ static constexpr u16 value{GAMECONTROLLER_RETURN_PORT}; };
template <> struct internal::address<"GameController"> { static constexpr util::FixedString value{
  #include "../configuration/gamecontroller.ip" // One-line file: just a string literal
}; };
#undef GAMECONTROLLER_DATA_PORT
#undef GAMECONTROLLER_RETURN_PORT

// Local
template <> struct internal::port::from<"local"> { static constexpr u16 value{static_cast<u16>(10000 + config::gamecontroller::team::upenn)}; };
template <> struct internal::port::to<"local"> { static constexpr u16 value{internal::port::from<"local">::value}; };
template <> struct internal::address<"local"> { static constexpr util::FixedString value{"10.0." + util::fixed_itoa<config::gamecontroller::team::upenn> + '.' + util::fixed_itoa<config::player::number>}; };

//%%%%%%%%%%%%%%%% Accessors

template <util::FixedString Device> requires registered<Device> inline constexpr char const* address{internal::address<Device>::value.c_str()};
namespace port {
template <util::FixedString Device> requires registered<Device> inline constexpr u16 from{internal::port::from<Device>::value};
template <util::FixedString Device> requires registered<Device> inline constexpr u16 to{internal::port::to<Device>::value};
} // namespace port

} // namespace ip
} // namespace config

#endif // CONFIG_IP_HPP
