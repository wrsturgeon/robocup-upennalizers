#ifndef CONFIG_IP_HPP
#define CONFIG_IP_HPP

#include <concepts>                   // for std::same_as
#include <fixed-string>               // for fixed::operator+, fixed::String, fixed::itoa

#include "config/gamecontroller.hpp"  // for GAMECONTROLLER_DATA_PORT, GAMECONTROLLER_RETURN_PORT
#include "config/player-number.hpp"   // for config::player::number
#include "config/teams.hpp"           // for config::gamecontroller::team::upenn

namespace config {
namespace ip {

//%%%%%%%%%%%%%%%% Internal wrappers to enforce type consistency and compile-time errors
// The basic idea is to start with an empty templated struct that we never use outside this file
//   For each valid template argument, we overwrite it with a specialization that has a member `value`
//   Then in the user-facing code (wherever we actually want the value), take the value of `struct<WhateverArgWePassed>::value`
//     If we pass an invalid template argument we get a compile-time error since there's no member `value`
//   And, plus, we can never have inconsistent types or half-assery across different devices since it's all the same code
namespace internal {
template <fixed::String Device> struct address {};
namespace port {
template <fixed::String Device> struct from {};
template <fixed::String Device> struct to {};
} // namespace port
} // namespace internal

template <fixed::String Device> concept registered = 
  requires { { internal::address<Device>::value.c_str() } -> std::same_as<char const*>; } and // fixed::String or std::string
  requires { { internal::port::from<Device>::value } -> std::same_as<u16 const&>; } and
  requires { { internal::port::to<Device>::value } -> std::same_as<u16 const&>; };

//%%%%%%%%%%%%%%%% Manually registering devices

// GameController
#ifndef GAMECONTROLLER_IP
#error GameController IP not defined; rules require unicast communication, so please pass its IP with -DGAMECONTROLLER_IP=...
#endif // GAMECONTROLLER_IP
template <> struct internal::port::from<"GameController">{ static constexpr u16 value{GAMECONTROLLER_DATA_PORT}; };
template <> struct internal::port::to<"GameController">{ static constexpr u16 value{GAMECONTROLLER_RETURN_PORT}; };
template <> struct internal::address<"GameController"> { static constexpr fixed::String value{STRINGIFY(GAMECONTROLLER_IP)}; };
#undef GAMECONTROLLER_DATA_PORT
#undef GAMECONTROLLER_RETURN_PORT

// Local
template <> struct internal::port::from<"local"> { static constexpr u16 value{static_cast<u16>(10000 + config::gamecontroller::team::upenn)}; };
template <> struct internal::port::to<"local"> { static constexpr u16 value{internal::port::from<"local">::value}; };
template <> struct internal::address<"local"> { static constexpr fixed::String value{"10.0." + fixed::itoa<config::gamecontroller::team::upenn> + '.' + fixed::itoa<config::player::number>}; };

//%%%%%%%%%%%%%%%% Accessors

template <fixed::String Device> requires registered<Device> inline constexpr char const* address{internal::address<Device>::value.c_str()};
namespace port {
template <fixed::String Device> requires registered<Device> inline constexpr u16 from{internal::port::from<Device>::value};
template <fixed::String Device> requires registered<Device> inline constexpr u16 to{internal::port::to<Device>::value};
} // namespace port

} // namespace ip
} // namespace config

#endif // CONFIG_IP_HPP
