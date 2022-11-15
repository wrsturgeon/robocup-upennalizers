// #pragma once // nope, stronger--see below
#ifdef GLOBAL_CONTEXT_INCLUDED
#error "Please never manually #include \"src/ctx/global-context.hpp\""; it's already included in \"src/prologue.hpp\", which is automatically prepended to every source file"
#else // GLOBAL_CONTEXT_INCLUDED
#define GLOBAL_CONTEXT_INCLUDED // first time only
#endif // GLOBAL_CONTEXT_INCLUDED

#include "src/ctx/context-fwd.hpp"
#include "src/ctx/loop.hpp"

#include "config/gamecontroller.hpp"

#include <algorithm> // std::copy_n
#include <cassert>   // assert

namespace ctx {

#if DEBUG
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-function"
#endif // DEBUG

static auto
make_spl_message() noexcept
-> spl::Message {
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

static auto
make_gc_message() noexcept
-> spl::GameControlReturnData {
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

static auto
parse(spl::GameControlData&& msg) noexcept
-> void {
#define TYPECHECK(LVALUE, RVALUE) static_assert(std::is_same_v<typename decltype(internal::LVALUE)::value_type, std::decay_t<decltype(msg.RVALUE)>>)
#if DEBUG || VERBOSE
#define UPDATE_ATOMIC(LVALUE, RVALUE, PRINT) TYPECHECK(LVALUE, RVALUE); if (msg.RVALUE != internal::LVALUE.exchange(std::move(msg.RVALUE), std::memory_order_relaxed)) { std::cout << #LVALUE << " updated -> " << PRINT(internal::LVALUE.load()) << std::endl; }
#else // DEBUG || VERBOSE
#define UPDATE_ATOMIC(LVALUE, RVALUE, PRINT) TYPECHECK(LVALUE, RVALUE); internal::LVALUE.store(std::move(msg.RVALUE), std::memory_order_relaxed);
#endif // DEBUG || VERBOSE

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

#if DEBUG
#pragma clang diagnostic pop
#endif // DEBUG

} // namespace ctx
