#pragma once

#include "src/util/stringify.hpp"

//%%%%%%%%%%%%%%%% Set the team number below (check the GameController's welcome screen drop-down menu)
#define TEAM_NUMBER 22

// Automated stuff
#define TEAM_NUMBER_STR STRINGIFY(TEAM_NUMBER)
#define TEAM_PORT (1000 + TEAM_NUMBER)
#define TEAM_PORT_STR STRINGIFY(TEAM_PORT)
namespace config {
namespace gc {
inline constexpr unsigned char team_number = TEAM_NUMBER;
} // namespace gc
} // namespace config
