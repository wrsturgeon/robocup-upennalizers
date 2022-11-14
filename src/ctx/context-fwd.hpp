#pragma once

#include "config/gamecontroller.hpp"
#include "config/spl-message.hpp"

#include <atomic> // std::atomic

namespace ctx {

// global atomic variables (in ctx::internal namespace, with thread-safe ctx:: accessors)
#define ATOMIC_VAR(NAME, TYPE, INIT)                                 \
  namespace internal { static auto NAME = std::atomic<TYPE>{INIT}; } \
  impure static auto NAME() noexcept -> TYPE { return internal::NAME.load(std::memory_order_relaxed); }
#if DEBUG
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-function"
#endif // DEBUG
ATOMIC_VAR(competition_phase, config::gamecontroller::competition::phase::t, config::gamecontroller::competition::phase::playoff) // better safe than sorry ig
ATOMIC_VAR(competition_type, config::gamecontroller::competition::type::t, config::gamecontroller::competition::type::normal)
ATOMIC_VAR(game_phase, config::gamecontroller::game::phase::t, config::gamecontroller::game::phase::normal)
ATOMIC_VAR(state, config::gamecontroller::state::t, config::gamecontroller::state::initial)
ATOMIC_VAR(set_play, config::gamecontroller::set_play::t, config::gamecontroller::set_play::none)
ATOMIC_VAR(first_half, u8, 1)
ATOMIC_VAR(kicking_team, u8, config::gamecontroller::color::blue)
ATOMIC_VAR(secs_remaining, i16, -1)
ATOMIC_VAR(secondary_time, i16, 0)
ATOMIC_VAR(team1, spl::TeamInfo, {})
ATOMIC_VAR(team2, spl::TeamInfo, {})
#if DEBUG
#pragma clang diagnostic pop
#endif // DEBUG
#undef ATOMIC_VAR

impure static auto make_spl_message() noexcept -> spl::Message;
impure static auto make_gc_message() noexcept -> spl::GameControlReturnData;
INLINE static auto parse(spl::GameControlData&&) noexcept -> void;
impure static auto done() noexcept -> bool { return (state() == config::gamecontroller::state::finished) and not first_half(); }

} // namespace ctx
