#pragma once

#include "src/util/stringify.hpp"

//%%%%%%%%%%%%%%%% Set the player number below (1: goalie; ...; 6: alternate)
#define PLAYER_NUMBER 2

// Automated stuff
#define PLAYER_NUMBER_STR STRINGIFY(PLAYER_NUMBER)
namespace config {
namespace player {
inline constexpr unsigned char number = PLAYER_NUMBER;
static_assert(number >= 1, "Player number must be >= 1");
static_assert(number <= 6, "Player number must be <= 6");
inline constexpr bool goalie = (number == 1);
inline constexpr bool alternate = (number == 6);
} // namespace player
} // namespace config
