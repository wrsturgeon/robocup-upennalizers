#ifndef MESSAGING_IO_HPP
#define MESSAGING_IO_HPP

// See legacy/Lib/Platform/NaoV4/GameControl/lua_GameControlReceiver.cc

#include "messaging/error.hpp"
#include "messaging/socket.hpp"

#include "config/gamecontroller.hpp"
#include "config/spl-message.hpp"
#include "config/wireless.hpp"

#include "file/contents.hpp"

#include <atomic>    // std::atomic
#include <cassert>   // assert
#include <cerrno>    // errno
#include <cstddef>   // std::size_t
#include <fstream>   // std::ifstream (to read config/runtime/gamecontroller.ip)
#include <iostream>  // std::cout
#include <string>    // std::to_string

namespace msg {

static
spl::GameControlData
recv_from_gc()
{
  static msg::Socket<msg::direction::incoming, msg::mode::unicast> const s{
        address_from_ip(config::ip::gamecontroller::address()),
        config::ip::gamecontroller::port::outgoing};
  return s.recv<spl::GameControlData>();
}

[[gnu::always_inline]] inline static void
send_to_gc()
{
  static msg::Socket<msg::direction::outgoing, msg::mode::unicast> const s{
        address_from_ip(config::ip::gamecontroller::address()),
        config::ip::gamecontroller::port::receiving};
  s.send(ctx::make_gc_message());
}

} // namespace msg

#endif // MESSAGING_IO_HPP
