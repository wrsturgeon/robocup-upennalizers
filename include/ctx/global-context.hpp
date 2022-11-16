#ifndef CTX_GLOBAL_CONTEXT_HPP
#define CTX_GLOBAL_CONTEXT_HPP

#include "ctx/context-fwd.hpp"
#include "ctx/loop.hpp"

#include "config/gamecontroller.hpp"

#include <algorithm> // std::copy_n
#include <cassert>   // assert

namespace ctx {

// static
// spl::Message
// make_spl_message()
// {
//   // TODO(wrsturgeon): submit a PR to the TC asking for a macro to disable constructors for SPL messages and similar structs
//   //   if we could, we could use designated initializers (i.e. { .version = ... }) for much faster and cleaner initialization
//   spl::Message msg{uninitialized<spl::Message>()};
//   std::copy_n(config::udp::msg::header, sizeof msg.header, static_cast<char*>(msg.header));
//   msg.version = config::udp::msg::version;
//   msg.teamNum = config::gamecontroller::team::upenn_number();
//   msg.playerNum = config::player::number;
//   msg.fallen = false;
//   msg.numOfDataBytes = 0;
//   // TODO(wrsturgeon): see TODO in the next function
//   return msg;
// }

static
spl::GameControlReturnData
make_gc_message()
{
  spl::GameControlReturnData msg{uninitialized<spl::GameControlReturnData>()};
  std::copy_n(config::udp::gamecontroller::recv::header, sizeof msg.header, static_cast<char*>(msg.header));
  msg.version = config::udp::gamecontroller::recv::version;
  msg.playerNum = config::player::number;
  msg.teamNum = config::gamecontroller::team::upenn_number();
  msg.fallen = false;
  std::fill_n(static_cast<float*>(msg.pose), sizeof msg.pose, 0.f);
  std::fill_n(static_cast<float*>(msg.ball), sizeof msg.ball, 0.f);
  msg.ballAge = -1.F;
  // TODO(wrsturgeon): make a separate structs for debugging and intra-team communication that are the size of SPL's data member
  return msg;
}

static
void
parse(spl::GameControlData&& msg) noexcept
{
  // NOLINTBEGIN(cppcoreguidelines-macro-usage)
#define TYPECHECK(LVALUE, RVALUE) static_assert(std::is_same_v<decltype(LVALUE()), std::decay_t<decltype(msg.RVALUE)>>)
#if DEBUG || VERBOSE
#define UPDATE_ATOMIC(LVALUE, RVALUE, PRINT) TYPECHECK(LVALUE, RVALUE); if (msg.RVALUE != internal::LVALUE().exchange(std::move(msg.RVALUE), std::memory_order_relaxed)) { try { std::cout << #LVALUE << " updated -> " << PRINT(internal::LVALUE().load(std::memory_order_relaxed)) << '\n'; } catch (std::exception& e) { std::cerr << "Exception in ctx::parse: " << e.what() << '\n'; } catch (...) { std::terminate(); } }
#else // DEBUG || VERBOSE
#define UPDATE_ATOMIC(LVALUE, RVALUE, PRINT) TYPECHECK(LVALUE, RVALUE); internal::LVALUE().store(std::move(msg.RVALUE), std::memory_order_relaxed);
#endif // DEBUG || VERBOSE
  // NOLINTEND(cppcoreguidelines-macro-usage)

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
  UPDATE_ATOMIC(kicking_team, kickingTeam, [](u8 team) { return config::gamecontroller::team::name(team); })
  UPDATE_ATOMIC(secs_remaining, secsRemaining, [](i16 s) { return std::to_string(s) + 's'; })
  UPDATE_ATOMIC(secondary_time, secondaryTime, [](i16 s) { return std::to_string(s) + 's'; })
  UPDATE_ATOMIC(team1, teams[0], )
  UPDATE_ATOMIC(team2, teams[1], )

#undef TYPECHECK
#undef UPDATE_ATOMIC
}

} // namespace ctx

#endif // CTX_GLOBAL_CONTEXT_HPP
