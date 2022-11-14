#pragma once

#include "src/ctx/loop-fwd.hpp"

#include "src/ctx/context-fwd.hpp"
#include "src/msg/io.hpp"

#include <cstddef>     // std::size_t

#if DEBUG
#include <iostream> // std::cout
#endif

namespace ctx {
namespace loop {

static auto
run() noexcept
-> void {

#if DEBUG
  std::cout << "Waiting for a GameController to open communication...\n";
#endif
  parse(msg::recv_from_gc()); // blocking

  // Continue until someone wins the game
  do {
    msg::send_to_gc();
    // msg::send_to_team(static_cast<spl::Message>(context));
    parse(msg::recv_from_gc()); // blocking
  } while (not ::ctx::done());
}

INLINE auto
parse(spl::GameControlData&& from_gc) noexcept
-> void {
  if ((from_gc.version == config::udp::gamecontroller::send::version) and !strncmp(from_gc.header, config::udp::gamecontroller::send::header, sizeof from_gc.header)) {
    ::ctx::parse(std::move(from_gc));
#if DEBUG
  } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warray-bounds"
    from_gc.header[4] = '\0'; // writing out of bounds into another struct member, but it's fine--nonsense anyway
#pragma clang diagnostic pop
    std::cout << "Invalid packet received (probably nonsense: version " << +from_gc.version << " (should be " << +config::udp::gamecontroller::send::version << "), header \"" << from_gc.header << "\" (should be \"" << config::udp::gamecontroller::send::header << "\"))\n";
#endif
  }
}

} // namespace loop
} // namespace ctx
