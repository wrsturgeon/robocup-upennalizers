#ifndef MSG_IO_HPP
#define MSG_IO_HPP

// See legacy/Lib/Platform/NaoV4/GameControl/lua_GameControlReceiver.cc

#include "msg/socket.hpp"

#include "config/gamecontroller.hpp"
#include "config/spl-message.hpp"
#include "config/wireless.hpp"

#include "util/read_file.hpp"

#include <atomic>    // std::atomic
#include <cassert>   // assert
#include <cerrno>    // errno
#include <cstddef>   // std::size_t
#include <fstream>   // std::ifstream (to read config/runtime/gamecontroller.ip)
#include <iostream>  // std::cout
#include <stdexcept> // std::runtime_error
#include <string>    // std::to_string

namespace msg {

static
spl::GameControlData
recv_from_gc()
{
  static msg::Socket<msg::direction::incoming, msg::mode::unicast> const s{
        address_from_ip(config::udp::gamecontroller::ip()),
        config::udp::gamecontroller::send::port};
  return s.recv<spl::GameControlData>();
}

[[gnu::always_inline]] inline static void
send_to_gc()
{
  static msg::Socket<msg::direction::outgoing, msg::mode::unicast> const s{
        address_from_ip(config::udp::gamecontroller::ip()),
        config::udp::gamecontroller::recv::port};
  s.send(ctx::make_gc_message());
}

} // namespace msg

#endif // MSG_IO_HPP
