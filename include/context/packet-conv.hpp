#ifndef CONTEXT_PACKET_CONV_HPP
#define CONTEXT_PACKET_CONV_HPP

#include "config/packet.hpp"
#include "config/player-number.hpp"

namespace context {

// static
// spl::Message
// make_spl_message()
// noexcept {
//   // TODO(wrsturgeon): submit a PR to the TC asking for a macro to disable constructors for SPL messages and similar structs
//   //   if we could, we could use designated initializers (i.e. { .version = ... }) for much faster and cleaner initialization
//   spl::Message msg{uninitialized<spl::Message>()};
//   std::copy_n(config::packet::spl::header, sizeof msg.header, static_cast<char*>(msg.header));
//   msg.version = config::packet::spl::version;
//   msg.teamNum = config::gamecontroller::team::upenn;
//   msg.playerNum = config::player::number;
//   msg.fallen = false;
//   msg.numOfDataBytes = 0;
//   // TODO(wrsturgeon): see TODO in the next function
//   return msg;
// }

static
spl::GameControlReturnData
make_gc_message()
noexcept {
  spl::GameControlReturnData msg{uninitialized<spl::GameControlReturnData>()};
  std::copy_n(config::packet::gc::to::header, sizeof msg.header, static_cast<char*>(msg.header));
  msg.version = config::packet::gc::to::version;
  msg.playerNum = config::player::number;
  msg.teamNum = config::gamecontroller::team::upenn;
  msg.fallen = false;
  std::fill_n(static_cast<float*>(msg.pose), sizeof msg.pose, 0.f);
  std::fill_n(static_cast<float*>(msg.ball), sizeof msg.ball, 0.f);
  msg.ballAge = -1.F;
  // TODO(wrsturgeon): make a separate structs for debugging and intra-team communication that are the size of SPL's data member
  return msg;
}

} // namespace context

#endif // CONTEXT_PACKET_CONV_HPP
