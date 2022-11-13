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
  do {
    parse(msg::recv_from_gc());
    msg::send_to_gc(static_cast<spl::GameControlReturnData>(context));
    // msg::send_to_team(static_cast<spl::Message>(context));
    std::this_thread::sleep_until(wait_until += update_period);
  } while (context and continue_looping);
}

template <config::gamecontroller::competition::phase::t CompetitionPhase,
          config::gamecontroller::competition::type ::t CompetitionType>
INLINE auto
Loop<CompetitionPhase, CompetitionType>::parse(std::optional<spl::GameControlData> const& from_gc) noexcept
-> void {
  if (from_gc and (from_gc->version == config::udp::gamecontroller::send::version) and !strncmp(from_gc->header, config::udp::gamecontroller::send::header, sizeof from_gc->header)) {
    context.parse(*from_gc);
#if DEBUG
  } else {
    if (from_gc) {
      std::cout << "Invalid packet ostensibly from GameController (probably nonsense: version " << from_gc->version << ", header " << from_gc->header << ")\n";
    }
#endif
  }
}

} // namespace ctx
