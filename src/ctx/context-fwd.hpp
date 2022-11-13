#pragma once

#include "src/ctx/context-fwd-fwd.hpp" // ikr

#include "src/ctx/loop-fwd.hpp"

#include "config/gamecontroller.hpp"
#include "config/spl-message.hpp"
#include "config/wireless.hpp"

#include <atomic> // std::atomic

namespace ctx {

#define ATOMIC_MEMBER(TYPE, NAME, INIT)                       \
    std::atomic<TYPE> _atomic_##NAME = INIT;                  \
  public:                                                     \
    pure auto NAME() const noexcept -> TYPE {                 \
      return _atomic_##NAME.load(std::memory_order_relaxed);  \
    }                                                         \
  private:

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpadded"
template <config::gamecontroller::competition::phase::t CompetitionPhase,
          config::gamecontroller::competition::type ::t CompetitionType>
class Context {
  // ATOMIC_MEMBER(u8, packet_number, 0)
  ATOMIC_MEMBER(config::gamecontroller::competition::phase::t, competition_phase, config::gamecontroller::competition::phase::playoff) // better safe than sorry ig
  ATOMIC_MEMBER(config::gamecontroller::competition::type::t, competition_type, config::gamecontroller::competition::type::normal)
  ATOMIC_MEMBER(config::gamecontroller::game::phase::t, game_phase, config::gamecontroller::game::phase::normal)
  ATOMIC_MEMBER(config::gamecontroller::state::t, state, config::gamecontroller::state::initial)
  ATOMIC_MEMBER(config::gamecontroller::set_play::t, set_play, config::gamecontroller::set_play::none)
  ATOMIC_MEMBER(u8, first_half, true)
  ATOMIC_MEMBER(u8, kicking_team, config::gamecontroller::team::blue)
  ATOMIC_MEMBER(i16, secs_remaining, -1)
  ATOMIC_MEMBER(i16, secondary_time, 0)
  ATOMIC_MEMBER(spl::TeamInfo, team1, {})
  ATOMIC_MEMBER(spl::TeamInfo, team2, {})
#if DEBUG
  static std::atomic<bool> first_context;
#endif
  ctx::Loop<CompetitionPhase, CompetitionType> loop;
 public:
  Context() noexcept;
  Context(Context const&) = delete;
  Context(Context&&) = delete;
  auto operator=(Context const&) -> Context& = delete;
  auto operator=(Context&&) -> Context& = delete;
  impure explicit operator spl::Message() const noexcept;
  impure explicit operator spl::GameControlReturnData() const noexcept;
  auto parse(spl::GameControlData&&) noexcept -> void;
  pure operator bool() const noexcept { return state() != config::gamecontroller::state::finished; }
};
#pragma clang diagnostic pop

} // namespace ctx
