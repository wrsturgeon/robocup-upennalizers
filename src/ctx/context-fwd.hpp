#pragma once

#include "src/ctx/context-fwd-fwd.hpp" // ikr

#include "src/ctx/loop-fwd.hpp"

#include "config/gamecontroller.hpp"
#include "config/spl-message.hpp"
#include "config/wireless.hpp"

#include <atomic> // std::atomic

namespace ctx {

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpadded"
template <config::gamecontroller::competition::phase::t CompetitionPhase,
          config::gamecontroller::competition::type ::t CompetitionType>
class Context {
  ctx::Loop<CompetitionPhase, CompetitionType> loop;
  std::atomic<config::gamecontroller::game::phase::t> _atomic_game_phase = config::gamecontroller::game::phase::normal;
  std::atomic<config::gamecontroller::penalty::t> _atomic_penalty = config::gamecontroller::penalty::none;
  std::atomic<config::gamecontroller::set_play::t> _atomic_set_play = config::gamecontroller::set_play::none;
  std::atomic<config::gamecontroller::state::t> _atomic_state = config::gamecontroller::state::initial;
#if DEBUG
  static std::atomic<bool> first_context;
#endif
 public:
  Context() noexcept;
  Context(Context const&) = delete;
  Context(Context&&) = delete;
  auto operator=(Context const&) -> Context& = delete;
  auto operator=(Context&&) -> Context& = delete;
  pure auto game_phase() const noexcept -> config::gamecontroller::game::phase::t { return _atomic_game_phase.load(); }
  pure auto    penalty() const noexcept -> config::gamecontroller::penalty::t     { return _atomic_penalty   .load(); }
  pure auto   set_play() const noexcept -> config::gamecontroller::set_play::t    { return _atomic_set_play  .load(); }
  pure auto      state() const noexcept -> config::gamecontroller::state::t       { return _atomic_state     .load(); }
  impure explicit operator spl::Message() const noexcept;
};
#pragma clang diagnostic pop

} // namespace ctx
