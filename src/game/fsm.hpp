#pragma once

#include "config/gamecontroller.hpp"

namespace game {

template <config::gamecontroller::competition::phase::t CompetitionPhase,
          config::gamecontroller::competition::type ::t CompetitionType>
struct FSM {
  config::gamecontroller::game::phase::t  game_phase  = config::gamecontroller::game::phase::normal;
  config::gamecontroller::penalty::t      penalty     = config::gamecontroller::penalty::none;
  config::gamecontroller::set_play::t     set_play    = config::gamecontroller::set_play::none;
  config::gamecontroller::state::t        state       = config::gamecontroller::state::initial;
  pure auto update() noexcept -> bool;
};

template <config::gamecontroller::competition::phase::t CompetitionPhase,
          config::gamecontroller::competition::type ::t CompetitionType>
pure auto
FSM<CompetitionPhase, CompetitionType>::update() noexcept
-> bool {
  return false; // for now; will exist in various branches
  return true; // continue
}

} // namespace game
