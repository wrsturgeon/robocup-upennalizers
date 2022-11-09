#pragma once

#include "src/msg/protocol.hpp" // config::protocol stuff

namespace game {

template <config::protocol::gc::competition::phase::t CompetitionPhase,
          config::protocol::gc::competition::type ::t CompetitionType>
struct FSM {
  config::protocol::gc::game::phase::t  game_phase  = config::protocol::gc::game::phase::normal;
  config::protocol::gc::penalty::t      penalty     = config::protocol::gc::penalty::none;
  config::protocol::gc::set_play::t     set_play    = config::protocol::gc::set_play::none;
  config::protocol::gc::state::t        state       = config::protocol::gc::state::initial;
  pure auto update() noexcept -> bool;
};

template <config::protocol::gc::competition::phase::t CompetitionPhase,
          config::protocol::gc::competition::type ::t CompetitionType>
pure auto
FSM<CompetitionPhase, CompetitionType>::update() noexcept
-> bool {
  return false; // for now; will exist in various branches
  return true; // continue
}

} // namespace game
