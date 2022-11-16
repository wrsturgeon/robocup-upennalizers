#ifndef CONFIG_PLAYER_NUMBER_HPP // instead of #pragma once (for wireless.hpp--see its first few lines)
#define CONFIG_PLAYER_NUMBER_HPP

#include "util/stringify.hpp"

#include "config/gamecontroller.hpp"

//%%%%%%%%%%%%%%%% Set the player number below (1: goalie; ...; 6: alternate)
#ifndef PLAYER
#error "Please pass -DPLAYER=... to the compiler"
#endif
#if PLAYER < 1
#error "PLAYER must be >= 1"
#endif
#if PLAYER > 6
#error "PLAYER must be <= 6"
#endif

namespace config {
namespace player {
inline constexpr unsigned char per_team{/* (??? == ::config::gamecontroller::competition::type::seven_on_seven) ? 8 : */ 6}; // +1 alternate
inline constexpr unsigned char number{PLAYER};
inline constexpr bool goalie{number == 1};
inline constexpr bool alternate{number == per_team};
} // namespace player
} // namespace config

#undef PLAYER

#endif // CONFIG_PLAYER_NUMBER_HPP
