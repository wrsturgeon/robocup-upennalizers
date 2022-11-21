#ifndef MESSAGING_IO_HPP
#define MESSAGING_IO_HPP

// See legacy/Lib/Platform/NaoV4/GameControl/lua_GameControlReceiver.cc

#include "messaging/socket.hpp"

#if DEBUG
#include "messaging/error.hpp"
#endif // DEBUG

#include "context/packet-conv.hpp"

#include "config/ip.hpp"

namespace msg {

impure static
spl::GameControlData
recv_from_gc()
noexcept {
  static msg::Socket<msg::direction::incoming, msg::mode::unicast> const s{
        util::ip::address_from_string(config::ip::address<"GameController">),
        config::ip::port::from<"GameController">};
  std::optional<spl::GameControlData> received{s.recv<spl::GameControlData>()};
  while (not received) {
    debug_print(std::cout, "Received an invalid packet; trying again...");
    received = s.recv<spl::GameControlData>(); }
  return *received;
}

[[gnu::always_inline]] inline static void
send_to_gc()
noexcept {
  static msg::Socket<msg::direction::outgoing, msg::mode::unicast> const s{
        util::ip::address_from_string(config::ip::address<"GameController">),
        config::ip::port::to<"GameController">};
  while (!s.send(context::make_gc_message())) { debug_print(std::cout, "Failed to send a packet; trying again..."); }
}

} // namespace msg

#endif // MESSAGING_IO_HPP
