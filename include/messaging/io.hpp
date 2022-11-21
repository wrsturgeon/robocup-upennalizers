#ifndef MESSAGING_IO_HPP
#define MESSAGING_IO_HPP

// See legacy/Lib/Platform/NaoV4/GameControl/lua_GameControlReceiver.cc

#include "concurrency/thread-priority.hpp"
#include "messaging/socket.hpp"

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
  std::optional<spl::GameControlData> received{uninitialized<spl::GameControlData>()};
  while (not (received = s.recv<spl::GameControlData>())) { concurrency::yield(); }
  return *received;
}

[[gnu::always_inline]] inline static void
send_to_gc()
noexcept {
  static msg::Socket<msg::direction::outgoing, msg::mode::unicast> const s{
        util::ip::address_from_string(config::ip::address<"GameController">),
        config::ip::port::to<"GameController">};
  while (!s.send(context::make_gc_message())) { concurrency::yield(); }
}

} // namespace msg

#endif // MESSAGING_IO_HPP
