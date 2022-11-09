#pragma once

/*
Interface with ZeroMQ (which in turn interfaces with UDP) to manage communication.
All UDP operations are designed to be run on their own thread (i.e. one thread for all messaging ops, not each on ... never mind).
Send: Our code --> 0MQ --> UDP --> GameController
Recv: Our code <-- 0MQ <-- UDP <-- GameController
*/

#include "src/msg/protocol.hpp"

#include "configuration/player-number.hpp"
#include "configuration/team-number.hpp"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything" // Ignore any errors from ZeroMQ code
#include "ext/cppzmq/zmq.hpp"
#pragma clang diagnostic pop

namespace msg {
namespace udp {

static void open_communication() noexcept {
  auto ctx = zmq::context_t{1}; // 1: one IO thread
  auto s_recv = zmq::socket_t{ctx, zmq::socket_type::dish};
  auto s_send = zmq::socket_t{ctx, zmq::socket_type::radio};
  s_recv.connect("udp://"); // TODO
  s_send.bind("udp://10.0." TEAM_NUMBER_STR "." PLAYER_NUMBER_STR ":10" TEAM_NUMBER_STR); // TODO: is this port right?
}

} // namespace udp
} // namespace msg
