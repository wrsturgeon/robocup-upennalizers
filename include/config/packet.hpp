#ifndef CONFIG_PACKET_HPP
#define CONFIG_PACKET_HPP

#include "config/gamecontroller.hpp"  // for GAMECONTROLLER_RETURN_STRUCT_HEADER, GAMECONTROLLER_RETURN_STRUCT_VERSION, GAMECONTROLLER_STRUCT_HEADER, GAMECONTROLLER_STRUCT_VERSION
#include "config/spl-message.hpp"     // for SPL_STANDARD_MESSAGE_DATA_SIZE, SPL_STANDARD_MESSAGE_STRUCT_HEADER, SPL_STANDARD_MESSAGE_STRUCT_VERSION

namespace config {
namespace packet {

namespace gc {

namespace from {
inline constexpr char const* header{GAMECONTROLLER_STRUCT_HEADER};
#undef GAMECONTROLLER_STRUCT_HEADER
inline constexpr u8 version{GAMECONTROLLER_STRUCT_VERSION};
static_assert(version == 14, "Updated SPL message version: please MANUALLY make sure we have a 1:1 correspondence (all fields accounted for), then hard-code this year's new version for next year's team. Thanks!");
} // namespace from

namespace to {
inline constexpr char const* header{GAMECONTROLLER_RETURN_STRUCT_HEADER};
#undef GAMECONTROLLER_RETURN_STRUCT_HEADER
inline constexpr u8 version{GAMECONTROLLER_RETURN_STRUCT_VERSION};
#undef GAMECONTROLLER_RETURN_STRUCT_VERSION
static_assert(version == 4, "Updated SPL message version: please MANUALLY make sure we have a 1:1 correspondence (all fields accounted for), then hard-code this year's new version for next year's team. Thanks!");
} // namespace to

} // namespace gc

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

#endif // CONFIG_PACKET_HPP
