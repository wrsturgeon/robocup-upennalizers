#pragma once

#include "src/ctx/context-fwd.hpp"

#include "src/ctx/loop.hpp"

#include "config/gamecontroller.hpp"

#include <algorithm> // std::copy_n
#include <cassert>   // assert
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
  msg.teamNum = config::gamecontroller::team::upenn;
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
  msg.playerNum = config::player::number;
  msg.teamNum = config::gamecontroller::team::upenn;
  msg.fallen = false;
  std::fill_n(msg.pose, sizeof msg.pose, '\0');
  std::fill_n(msg.ball, sizeof msg.ball, '\0');
  msg.ballAge = -1.F;
  // TODO
  return msg;
}

template <config::gamecontroller::competition::phase::t CompetitionPhase,
          config::gamecontroller::competition::type ::t CompetitionType>
auto
Context<CompetitionPhase, CompetitionType>::parse(spl::GameControlData&& msg) noexcept
-> void
{
#define TYPECHECK(LVALUE, RVALUE) static_assert(std::is_same_v<typename decltype(_atomic_##LVALUE)::value_type, std::decay_t<decltype(msg.RVALUE)>>)
#if DEBUG
#define UPDATE_ATOMIC(LVALUE, RVALUE, PRINT) TYPECHECK(LVALUE, RVALUE); if (msg.RVALUE != _atomic_##LVALUE.exchange(std::move(msg.RVALUE), std::memory_order_relaxed)) { std::cout << #LVALUE << " updated -> " << PRINT(_atomic_##LVALUE.load()) << std::endl; }
#else // DEBUG
#define UPDATE_ATOMIC(LVALUE, RVALUE, PRINT) TYPECHECK(LVALUE, RVALUE); _atomic_##LVALUE.store(std::move(msg.RVALUE), std::memory_order_relaxed);
#endif // DEBUG

  // In struct order
  // msg.header is valid (since this fn was called) & can be ignored
  // msg.version is valid (since this fn was called) & can be ignored
  // UPDATE_ATOMIC(packet_number, packetNumber) // For now, ignore packetNumber
  assert(msg.playersPerTeam == config::player::per_team);
  UPDATE_ATOMIC(competition_phase, competitionPhase, config::gamecontroller::competition::phase::print)
  UPDATE_ATOMIC(competition_type, competitionType, config::gamecontroller::competition::type::print)
  UPDATE_ATOMIC(game_phase, gamePhase, config::gamecontroller::game::phase::print)
  UPDATE_ATOMIC(state, state, config::gamecontroller::state::print)
  UPDATE_ATOMIC(set_play, setPlay, config::gamecontroller::set_play::print)
  UPDATE_ATOMIC(first_half, firstHalf, static_cast<bool>)
  UPDATE_ATOMIC(kicking_team, kickingTeam, [](u8 team) { return config::gamecontroller::team::number(team); })
  UPDATE_ATOMIC(secs_remaining, secsRemaining, [](i16 s) { return std::to_string(s) + 's'; })
  UPDATE_ATOMIC(secondary_time, secondaryTime, [](i16 s) { return std::to_string(s) + 's'; })
  UPDATE_ATOMIC(team1, teams[0], )
  UPDATE_ATOMIC(team2, teams[1], )

#undef TYPECHECK
#undef UPDATE_ATOMIC
}

} // namespace ctx
