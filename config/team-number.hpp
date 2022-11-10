#ifndef CONFIG_TEAM_NUMBER_INCLUDED // instead of #pragma once (for wireless.hpp--see its first few lines)
#define CONFIG_TEAM_NUMBER_INCLUDED

#include "src/util/stringify.hpp"

//%%%%%%%%%%%%%%%% Set the team number below (check the GameController's welcome screen drop-down menu)
#define TEAM_NUMBER 22

// Automated stuff--no need to edit
#define TEAM_NUMBER_STR STRINGIFY(TEAM_NUMBER)

#define TEAM_PORT (10000 + TEAM_NUMBER)
// Workaround: can't actually perform addition in a macro
#if TEAM_NUMBER < 10
#define TEAM_PORT_STR "1000" TEAM_NUMBER_STR
#elif TEAM_NUMBER < 100
#define TEAM_PORT_STR "100" TEAM_NUMBER_STR
#elif TEAM_NUMBER < 1000
#define TEAM_PORT_STR "10" TEAM_NUMBER_STR
#elif TEAM_NUMBER < 10000
#define TEAM_PORT_STR "1" TEAM_NUMBER_STR
#else
#error "TEAM_NUMBER is too large"
#endif
namespace config {
namespace gamecontroller {
inline constexpr unsigned char team_number = TEAM_NUMBER;
} // namespace gamecontroller
} // namespace config

#endif // CONFIG_TEAM_NUMBER_INCLUDED
