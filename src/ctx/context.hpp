#pragma once

#include "src/ctx/context-fwd.hpp"

#include "src/ctx/loop.hpp"

#include "config/gamecontroller.hpp"

#include <algorithm> // std::copy_n
#include <utility>   // std::ref

namespace ctx {

#if DEBUG
template <config::gamecontroller::competition::phase::t CompetitionPhase,
          config::gamecontroller::competition::type ::t CompetitionType>
std::atomic<bool> Context<CompetitionPhase, CompetitionType>::first_context = true;
#endif

template <config::gamecontroller::competition::phase::t CompetitionPhase,
          config::gamecontroller::competition::type ::t CompetitionType>
Context<CompetitionPhase, CompetitionType>::Context() noexcept
    : loop{*this}
{
#if DEBUG
  assert(first_context.exchange(false));
#endif
}

template <config::gamecontroller::competition::phase::t CompetitionPhase,
          config::gamecontroller::competition::type ::t CompetitionType>
impure
Context<CompetitionPhase, CompetitionType>::operator spl::Message() const noexcept
{
  auto msg = uninitialized<spl::Message>();
  std::copy_n(config::udp::msg::header, sizeof msg.header, msg.header);
  msg.version = config::udp::msg::version;
  msg.teamNum = config::gamecontroller::team_number;
  msg.playerNum = config::player::number;
  msg.fallen = false;
  msg.numOfDataBytes = 0;
  // TODO
  return msg;
}

template <config::gamecontroller::competition::phase::t CompetitionPhase,
          config::gamecontroller::competition::type ::t CompetitionType>
impure
Context<CompetitionPhase, CompetitionType>::operator spl::GameControlReturnData() const noexcept
{
  auto msg = uninitialized<spl::GameControlReturnData>();
  std::copy_n(config::udp::gamecontroller::recv::header, sizeof msg.header, msg.header);
  msg.version = config::udp::gamecontroller::recv::version;
  msg.teamNum = config::gamecontroller::team_number;
  msg.playerNum = config::player::number;
  msg.fallen = false;
  // TODO
  return msg;
}

template <config::gamecontroller::competition::phase::t CompetitionPhase,
          config::gamecontroller::competition::type ::t CompetitionType>
auto
Context<CompetitionPhase, CompetitionType>::parse(spl::GameControlData const& /*from_gc*/) noexcept
-> void
{
  // TODO
}

} // namespace ctx
