#ifndef CONFIG_SPL_MESSAGE_HPP
#define CONFIG_SPL_MESSAGE_HPP

#include "config/gamecontroller.hpp"

#if DEBUG || VERBOSE
#include <iostream>
#endif

namespace spl {
#define SPLStandardMessage Message // to avoid typing spl::SPL...
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything" // Ignore any errors from SPL code
#include "ext/GameController/examples/c/SPLStandardMessage.h"
#pragma clang diagnostic pop
#undef SPLStandardMessage

#if DEBUG || VERBOSE

// static
// std::ostream&
// operator<<(std::ostream& os, Message const& msg) noexcept
// {
//   os << '[' << config::gamecontroller::team::name(msg.teamNum) << " Player #" << +msg.playerNum;
//   if (msg.fallen) { os << ", FALLEN,"; }
//   os << " at (" << msg.pose[0] << ' ' << msg.pose[1] << ' ' << msg.pose[2] << "), ball (" << msg.ball[0] << ' ' << msg.ball[1] << ") (";
// #pragma clang diagnostic push
// #pragma clang diagnostic ignored "-Wfloat-equal"
//   if (msg.ballAge != -1.F) { os << "last seen " << msg.ballAge << "s ago)"; } else { os << "never seen)"; }
// #pragma clang diagnostic pop
//   return os << " + " << +msg.numOfDataBytes << "B data]";
// }

#endif // DEBUG || VERBOSE

} // namespace spl

#endif // CONFIG_SPL_MESSAGE_HPP
