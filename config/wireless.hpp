#pragma once

#ifdef CONFIG_PLAYER_NUMBER_INCLUDED
#error "Please never manually #include \"config/player-number.hpp\" (automatically included with \"config/wireless.hpp\"); please search for wherever it's included and include this instead"
#endif
#ifdef CONFIG_TEAM_NUMBER_INCLUDED
#error "Please never manually #include \"config/team-number.hpp\" (automatically included with \"config/wireless.hpp\"); please search for wherever it's included and include this instead"
#endif

#include "config/gamecontroller.hpp"
#include "config/player-number.hpp"
#include "config/spl-message.hpp"
#include "config/teams.hpp"

// not this tho
#define PLAYER_IP "10.0." TEAM_NUMBER_STR "." PLAYER_NUMBER_STR

namespace config {

namespace player {
inline std::string const ip = "10.0." + std::to_string(config::gamecontroller::team::upenn) + "." + std::to_string(config::player::number);
} // namespace player

namespace udp {

inline u16 const team_port = 10000 + config::gamecontroller::team::upenn;

// From ext/GameController/examples/c/RoboCupGameControlData.h (included via config/protocol.hpp):
namespace gamecontroller {

namespace send {
inline constexpr u16 port = GAMECONTROLLER_DATA_PORT;
#undef GAMECONTROLLER_DATA_PORT
inline constexpr char const* header = GAMECONTROLLER_STRUCT_HEADER;
#undef GAMECONTROLLER_STRUCT_HEADER
inline constexpr u8 version = GAMECONTROLLER_STRUCT_VERSION;
static_assert(version == 14, "Updated SPL message version: please MANUALLY make sure we have a 1:1 correspondence (all fields accounted for), then hard-code this year's new version for next year's team. Thanks!");
} // namespace send

namespace recv {
inline constexpr u16 port = GAMECONTROLLER_RETURN_PORT;
#undef GAMECONTROLLER_RETURN_PORT
inline constexpr char const* header = GAMECONTROLLER_RETURN_STRUCT_HEADER;
#undef GAMECONTROLLER_RETURN_STRUCT_HEADER
inline constexpr u8 version = GAMECONTROLLER_RETURN_STRUCT_VERSION;
#undef GAMECONTROLLER_RETURN_STRUCT_VERSION
static_assert(version == 4, "Updated SPL message version: please MANUALLY make sure we have a 1:1 correspondence (all fields accounted for), then hard-code this year's new version for next year's team. Thanks!");
} // namespace recv

} // namespace gamecontroller

// From ext/GameController/examples/c/SPLStandardMessage.h (included via config/protocol.hpp):
namespace msg {
inline constexpr char const* header = SPL_STANDARD_MESSAGE_STRUCT_HEADER;
#undef SPL_STANDARD_MESSAGE_STRUCT_HEADER
inline constexpr u8 version = SPL_STANDARD_MESSAGE_STRUCT_VERSION;
#undef SPL_STANDARD_MESSAGE_STRUCT_VERSION
inline constexpr u16 data_size = SPL_STANDARD_MESSAGE_DATA_SIZE;
#undef SPL_STANDARD_MESSAGE_DATA_SIZE
static_assert(version == 7, "Updated SPL message version: please MANUALLY make sure we have a 1:1 correspondence (all fields accounted for), then hard-code this year's new version for next year's team. Thanks!");
} // namespace msg

} // namespace udp

} // namespace config

#undef PLAYER_NUMBER_STR // Safe to delete (see the macros at the top of this file)
#undef PLAYER_NUMBER

#undef TEAM_NUMBER_STR
#undef TEAM_NUMBER
#undef TEAM_PORT_STR
#undef TEAM_PORT

#undef GAMECONTROLLER_IP

// No more macros floating around
