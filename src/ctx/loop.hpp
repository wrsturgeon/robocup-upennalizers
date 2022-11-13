#pragma once

#include "src/ctx/loop-fwd.hpp"

#include "src/ctx/context-fwd.hpp"

#include <cstddef>   // std::size_t
#include <stdexcept> // std::runtime_error

#if DEBUG
#include <iostream> // std::cout
#endif

namespace ctx {

#if DEBUG
template <config::gamecontroller::competition::phase::t CompetitionPhase,
          config::gamecontroller::competition::type ::t CompetitionType>
std::atomic<bool> Loop<CompetitionPhase, CompetitionType>::any_loop_started = false;
#endif

template <config::gamecontroller::competition::phase::t CompetitionPhase,
          config::gamecontroller::competition::type ::t CompetitionType>
auto
Loop<CompetitionPhase, CompetitionType>::operator()() noexcept
-> void {
#if DEBUG
  std::cout << "Waiting for a GameController to open communication...\n";
#endif
  parse(msg::recv_from_gc()); // blocking
  do {
    msg::send_to_gc(static_cast<spl::GameControlReturnData>(context));
    // msg::send_to_team(static_cast<spl::Message>(context));
    parse(msg::recv_from_gc()); // blocking
  } while (context); // if the above line tells us game over, don't send anything more (hence parse at the end of the loop)
}

template <config::gamecontroller::competition::phase::t CompetitionPhase,
          config::gamecontroller::competition::type ::t CompetitionType>
INLINE auto
Loop<CompetitionPhase, CompetitionType>::parse(std::optional<spl::GameControlData>&& from_gc) noexcept
-> void {
  if (from_gc and (from_gc->version == config::udp::gamecontroller::send::version) and !strncmp(from_gc->header, config::udp::gamecontroller::send::header, sizeof from_gc->header)) {
    context.parse(std::move(*from_gc));
#if DEBUG
  } else {
    if (from_gc) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warray-bounds"
      from_gc->header[4] = '\0'; // writing out of bounds into another struct member, but it's fine--nonsense anyway
#pragma clang diagnostic pop
      std::cout << "Invalid packet received (probably nonsense: version " << +from_gc->version << " (should be " << +config::udp::gamecontroller::send::version << "), header \"" << from_gc->header << "\" (should be \"" << config::udp::gamecontroller::send::header << "\"))\n";
    }
#endif
  }
}

} // namespace ctx
