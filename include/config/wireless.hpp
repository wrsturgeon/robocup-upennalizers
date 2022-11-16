#ifndef CONFIG_WIRELESS_HPP
#define CONFIG_WIRELESS_HPP

#include "config/gamecontroller.hpp"
#include "config/player-number.hpp"
#include "config/spl-message.hpp"
#include "config/teams.hpp"

#include "util/read_file.hpp"

namespace config {

// namespace player {
// impure static
// std::string
// ip()
// {
//   static std::string const ip{"10.0." + std::to_string(config::gamecontroller::team::upenn_number()) + "." + std::to_string(config::player::number)};
//   return ip;
// }
// } // namespace player

namespace udp {

// impure static
// u16
// team_port()
// {
//   static u16 const port{static_cast<u16>(10000 + config::gamecontroller::team::upenn_number())};
//   return port;
// };

namespace gamecontroller {

static
char const*
ip()
{
  static std::string const ip{util::read_file("include/config/runtime/gamecontroller.ip")};
  return ip.c_str();
}

namespace send {
inline constexpr u16 port{GAMECONTROLLER_DATA_PORT};
#undef GAMECONTROLLER_DATA_PORT
inline constexpr char const* header{GAMECONTROLLER_STRUCT_HEADER};
#undef GAMECONTROLLER_STRUCT_HEADER
inline constexpr u8 version{GAMECONTROLLER_STRUCT_VERSION};
static_assert(version == 14, "Updated SPL message version: please MANUALLY make sure we have a 1:1 correspondence (all fields accounted for), then hard-code this year's new version for next year's team. Thanks!");
} // namespace send

namespace recv {
inline constexpr u16 port{GAMECONTROLLER_RETURN_PORT};
#undef GAMECONTROLLER_RETURN_PORT
inline constexpr char const* header{GAMECONTROLLER_RETURN_STRUCT_HEADER};
#undef GAMECONTROLLER_RETURN_STRUCT_HEADER
inline constexpr u8 version{GAMECONTROLLER_RETURN_STRUCT_VERSION};
#undef GAMECONTROLLER_RETURN_STRUCT_VERSION
static_assert(version == 4, "Updated SPL message version: please MANUALLY make sure we have a 1:1 correspondence (all fields accounted for), then hard-code this year's new version for next year's team. Thanks!");
} // namespace recv

} // namespace gamecontroller

// From ext/GameController/examples/c/SPLStandardMessage.h (included via config/protocol.hpp):
namespace msg {
inline constexpr char const* header{SPL_STANDARD_MESSAGE_STRUCT_HEADER};
#undef SPL_STANDARD_MESSAGE_STRUCT_HEADER
inline constexpr u8 version{SPL_STANDARD_MESSAGE_STRUCT_VERSION};
#undef SPL_STANDARD_MESSAGE_STRUCT_VERSION
inline constexpr u16 data_size{SPL_STANDARD_MESSAGE_DATA_SIZE};
#undef SPL_STANDARD_MESSAGE_DATA_SIZE
static_assert(version == 7, "Updated SPL message version: please MANUALLY make sure we have a 1:1 correspondence (all fields accounted for), then hard-code this year's new version for next year's team. Thanks!");
} // namespace msg

} // namespace udp

} // namespace config

// No more macros floating around

#endif // CONFIG_WIRELESS_HPP
