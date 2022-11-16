#ifndef CONFIG_WIRELESS_HPP
#define CONFIG_WIRELESS_HPP

#include "config/gamecontroller.hpp"
#include "config/player-number.hpp"
#include "config/spl-message.hpp"
#include "config/teams.hpp"

#include "file/contents.hpp"

namespace config {

namespace ip {

namespace my {
impure static
char const*
address()
{
  static std::string const addr{"10.0." + std::to_string(config::gamecontroller::team::upenn_number()) + "." + std::to_string(config::player::number)};
  return addr.c_str();
}
impure static
u16
port()
{
  static u16 const p{static_cast<u16>(10000 + config::gamecontroller::team::upenn_number())};
  return p;
};
} // namespace my

namespace gamecontroller {
static
char const*
address()
{
  static std::string const ip{file::contents<"include/config/runtime/gamecontroller.ip">()};
  return ip.c_str();
}
namespace port {
inline constexpr u16 receiving{GAMECONTROLLER_RETURN_PORT};
#undef GAMECONTROLLER_RETURN_PORT
inline constexpr u16 outgoing{GAMECONTROLLER_DATA_PORT};
#undef GAMECONTROLLER_DATA_PORT
} // namespace port

} // namespace gamecontroller

} // namespace ip

namespace packet {

namespace gamecontroller {

namespace send {
inline constexpr char const* header{GAMECONTROLLER_STRUCT_HEADER};
#undef GAMECONTROLLER_STRUCT_HEADER
inline constexpr u8 version{GAMECONTROLLER_STRUCT_VERSION};
static_assert(version == 14, "Updated SPL message version: please MANUALLY make sure we have a 1:1 correspondence (all fields accounted for), then hard-code this year's new version for next year's team. Thanks!");
} // namespace send

namespace recv {
inline constexpr char const* header{GAMECONTROLLER_RETURN_STRUCT_HEADER};
#undef GAMECONTROLLER_RETURN_STRUCT_HEADER
inline constexpr u8 version{GAMECONTROLLER_RETURN_STRUCT_VERSION};
#undef GAMECONTROLLER_RETURN_STRUCT_VERSION
static_assert(version == 4, "Updated SPL message version: please MANUALLY make sure we have a 1:1 correspondence (all fields accounted for), then hard-code this year's new version for next year's team. Thanks!");
} // namespace recv

} // namespace gamecontroller

// From ext/GameController/examples/c/SPLStandardMessage.h (included via config/protocol.hpp):
namespace spl {
inline constexpr char const* header{SPL_STANDARD_MESSAGE_STRUCT_HEADER};
#undef SPL_STANDARD_MESSAGE_STRUCT_HEADER
inline constexpr u8 version{SPL_STANDARD_MESSAGE_STRUCT_VERSION};
#undef SPL_STANDARD_MESSAGE_STRUCT_VERSION
inline constexpr u16 data_size{SPL_STANDARD_MESSAGE_DATA_SIZE};
#undef SPL_STANDARD_MESSAGE_DATA_SIZE
static_assert(version == 7, "Updated SPL message version: please MANUALLY make sure we have a 1:1 correspondence (all fields accounted for), then hard-code this year's new version for next year's team. Thanks!");
} // namespace spl

} // namespace packet

} // namespace config

// No more macros floating around

#endif // CONFIG_WIRELESS_HPP
