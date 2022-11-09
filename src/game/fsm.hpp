#pragma once

#include "src/msg/protocol.hpp" // config::protocol stuff

namespace game {

template <config::gc::competition::phase::t CompetitionPhase,
          config::gc::competition::type ::t CompetitionType>
struct FSM {
  config::gc::game::phase::t  game_phase  = config::gc::game::phase::normal;
  config::gc::penalty::t      penalty     = config::gc::penalty::none;
  config::gc::set_play::t     set_play    = config::gc::set_play::none;
  config::gc::state::t        state       = config::gc::state::initial;
  pure auto update() noexcept -> bool;
};

template <config::gc::competition::phase::t CompetitionPhase,
          config::gc::competition::type ::t CompetitionType>
pure auto
FSM<CompetitionPhase, CompetitionType>::update() noexcept
-> bool {
  return false; // for now; will exist in various branches
  return true; // continue
}

} // namespace game
