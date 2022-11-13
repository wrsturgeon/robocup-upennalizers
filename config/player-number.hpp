#ifndef CONFIG_PLAYER_NUMBER_INCLUDED // instead of #pragma once (for wireless.hpp--see its first few lines)
#define CONFIG_PLAYER_NUMBER_INCLUDED

#include "src/util/stringify.hpp"

#include "config/gamecontroller.hpp"

//%%%%%%%%%%%%%%%% Set the player number below (1: goalie; ...; 6: alternate)
#define PLAYER_NUMBER 2

// Automated stuff
#define PLAYER_NUMBER_STR STRINGIFY(PLAYER_NUMBER)
namespace config {
namespace player {
inline constexpr unsigned char per_team = /* (??? == ::config::gamecontroller::competition::type::seven_on_seven) ? 8 : */ 6; // +1 alternate
inline constexpr unsigned char number = PLAYER_NUMBER;
static_assert(number >= 1, "Player number must be >= 1");
static_assert(number <= 6, "Player number must be <= 6");
inline constexpr bool goalie = (number == 1);
inline constexpr bool alternate = (number == per_team);
} // namespace player
} // namespace config

#endif // CONFIG_PLAYER_NUMBER_INCLUDED
