#pragma once

namespace game {

template <config::gamecontroller::competition::phase::t CompetitionPhase,
          config::gamecontroller::competition::type ::t CompetitionType>
pure static auto
update(FSM<CompetitionPhase, CompetitionType> const& /*fsm*/) noexcept
-> bool {
  return false; // for now; will exist in various branches
  return true; // continue
}

} // namespace game
