// C++ interpretation of legacy/Player/Run/main.lua

#pragma once

#include "src/body/fsm.hpp"
#include "src/head/fsm.hpp"
#include "src/game/fsm.hpp"
#include "src/body/update.hpp"
#include "src/head/update.hpp"
#include "src/game/update.hpp"

namespace loop {

template <config::gc::competition::phase::t CompetitionPhase,
          config::gc::competition::type ::t CompetitionType>
pure static auto
update(body::FSM& body_fsm, head::FSM& head_fsm, game::FSM<CompetitionPhase, CompetitionType>& game_fsm) noexcept
-> bool {
  return ( // Update FSMs then act
    body_fsm.update() and
    head_fsm.update() and
    game_fsm.update() and
    body::update(body_fsm) and
    head::update(head_fsm) and
    game::update(game_fsm));
}

template <config::gc::competition::phase::t CompetitionPhase,
          config::gc::competition::type ::t CompetitionType>
pure static auto
start(body::FSM& body_fsm, head::FSM& head_fsm, game::FSM<CompetitionPhase, CompetitionType>& game_fsm) noexcept
-> bool {
  return update(body_fsm, head_fsm, game_fsm); // for now
}

} // namespace loop
