#pragma once

// See legacy/Lib/Platform/NaoV4/GameControl/lua_GameControlReceiver.cc

#include "src/msg/socket.hpp"

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

static auto
recv_from_gc()
-> spl::GameControlData {
  static auto s = msg::Socket<msg::direction::incoming, msg::mode::unicast>{
        address_from_ip(config::udp::gamecontroller::ip()),
        config::udp::gamecontroller::send::port};
  return s.recv<spl::GameControlData>();
}

[[gnu::always_inline]] inline static auto
send_to_gc()
-> void {
  static auto s = msg::Socket<msg::direction::outgoing, msg::mode::unicast>{
        address_from_ip(config::udp::gamecontroller::ip()),
        config::udp::gamecontroller::recv::port};
  s.send(ctx::make_gc_message());
}

} // namespace msg
