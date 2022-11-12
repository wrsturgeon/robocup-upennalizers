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
#include "config/team-number.hpp"

//%%%%%%%%%%%%%%%% Feel free to change
#define GAMECONTROLLER_IP "192.168.1.187"

// not this tho
#define PLAYER_IP "10.0." TEAM_NUMBER_STR "." PLAYER_NUMBER_STR

namespace config {

namespace gamecontroller {
inline constexpr char const* ip = GAMECONTROLLER_IP;
} // namespace gamecontroller

namespace player {
inline constexpr char const* ip = PLAYER_IP;
} // namespace player

namespace udp {

inline constexpr u16 team_port = TEAM_PORT;
inline constexpr char const* team_port_str = TEAM_PORT_STR;
inline constexpr char const* to_players = "udp://" PLAYER_IP ":" TEAM_PORT_STR;
inline constexpr char const* to_gamecontroller = "udp://" PLAYER_IP ":" STRINGIFY(GAMECONTROLLER_RETURN_PORT);
inline constexpr char const* from_players = "udp://*:" TEAM_PORT_STR;
inline constexpr char const* from_gamecontroller = "udp://" GAMECONTROLLER_IP ":" STRINGIFY(GAMECONTROLLER_DATA_PORT);

// From ext/GameController/examples/c/RoboCupGameControlData.h (included via config/protocol.hpp):
namespace gamecontroller {

namespace send {
inline constexpr u16 port = GAMECONTROLLER_DATA_PORT;
#undef GAMECONTROLLER_DATA_PORT
inline constexpr char const* header = GAMECONTROLLER_STRUCT_HEADER;
#undef GAMECONTROLLER_STRUCT_HEADER
inline constexpr u8 version = GAMECONTROLLER_STRUCT_VERSION;
} // namespace send

namespace recv {
inline constexpr u16 port = GAMECONTROLLER_RETURN_PORT;
#undef GAMECONTROLLER_RETURN_PORT
inline constexpr char const* header = GAMECONTROLLER_RETURN_STRUCT_HEADER;
#undef GAMECONTROLLER_RETURN_STRUCT_HEADER
inline constexpr u8 version = GAMECONTROLLER_RETURN_STRUCT_VERSION;
#undef GAMECONTROLLER_RETURN_STRUCT_VERSION
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
} // namespace msg

} // namespace udp

} // namespace config

#undef PLAYER_NUMBER_STR // Safe to delete (see the macros at the top of this file)
#undef PLAYER_NUMBER

#undef TEAM_NUMBER_STR
#undef TEAM_NUMBER
#undef TEAM_PORT_STR
#undef TEAM_PORT

#undef PLAYER_IP
#undef GAMECONTROLLER_IP

// No more macros floating around
