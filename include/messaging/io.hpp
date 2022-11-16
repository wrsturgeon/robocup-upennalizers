#ifndef MESSAGING_IO_HPP
#define MESSAGING_IO_HPP

// See legacy/Lib/Platform/NaoV4/GameControl/lua_GameControlReceiver.cc

#include "messaging/error.hpp"
#include "messaging/socket.hpp"

#include "file/contents.hpp"

#include "context/packet-conv.hpp"

#include "config/ip.hpp"

namespace msg {

impure static
spl::GameControlData
recv_from_gc() {
  static msg::Socket<msg::direction::incoming, msg::mode::unicast> const s{
        config::ip::address<"GameController">(),
        config::ip::port<"GameController">::from()};
  return s.recv<spl::GameControlData>();
}

[[gnu::always_inline]] inline static void
send_to_gc() {
  static msg::Socket<msg::direction::outgoing, msg::mode::unicast> const s{
        config::ip::address<"GameController">(),
        config::ip::port<"GameController">::to()};
  s.send(context::make_gc_message());
}

} // namespace msg

#endif // MESSAGING_IO_HPP
