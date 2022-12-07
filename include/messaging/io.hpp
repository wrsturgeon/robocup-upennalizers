#ifndef MESSAGING_IO_HPP
#define MESSAGING_IO_HPP

// See legacy/Lib/Platform/NaoV4/GameControl/lua_GameControlReceiver.cc

#include <fixed-string>                     // for fixed::String
#include <optional>                         // for std::optional

#include "concurrency/thread-priority.hpp"  // for concurrency::yield
#include "config/gamecontroller.hpp"        // for spl::GameControlData, spl::GameControlReturnData
#include "config/ip.hpp"                    // for config::ip::address, config::ip::port::from, config::ip::port::to
#include "context/packet-conv.hpp"          // for context::make_gc_message
#include "messaging/socket.hpp"             // for msg::direction, msg::mode, msg::Socket
#include "util/ip.hpp"                      // for util::ip::address_from_string

namespace msg {

impure static
spl::GameControlData
recv_from_gc()
noexcept {
  static msg::Socket<msg::direction::incoming, msg::mode::unicast> const s{
        util::ip::address_from_string(config::ip::address<"GameController">),
        config::ip::port::from<"GameController">};
  std::optional<spl::GameControlData> received{uninitialized<std::optional<spl::GameControlData>>()};
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
