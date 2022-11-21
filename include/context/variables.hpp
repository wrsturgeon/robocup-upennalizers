#ifndef CONTEXT_VARIABLES_HPP
#define CONTEXT_VARIABLES_HPP

#include <algorithm> // std::copy_n
#include <atomic>    // std::atomic
#include <cassert>   // assert

namespace context {

// We have to be very careful with these to avoid throwing exceptions before calling main()
//   (if we do, we can't get an exception, just get a system kill signal with no explanation)
// Runtime static variables inside functions are initialized on the first function call
// But we don't want to return std::atomic or mutable references, so two layers of functions
// NOLINTNEXTLINE(cppcoreguidelines-macro-usage)
#define ATOMIC_VAR(NAME, TYPE, INIT)                         \
                                                             \
  namespace internal {                                       \
    impure static                                            \
    std::atomic<TYPE>&                                       \
    NAME() noexcept                                          \
    {                                                        \
      static std::atomic<TYPE> value{INIT};                  \
      return value;                                          \
    }                                                        \
  }                                                          \
                                                             \
  impure static                                              \
  TYPE                                                       \
  NAME() noexcept                                            \
  {                                                          \
    return internal::NAME().load(std::memory_order_relaxed); \
  }

#if DEBUG
#endif // DEBUG
ATOMIC_VAR(competition_phase, config::gamecontroller::competition::phase::t, config::gamecontroller::competition::phase::playoff) // better safe than sorry ig
ATOMIC_VAR(competition_type, config::gamecontroller::competition::type::t, config::gamecontroller::competition::type::normal)
ATOMIC_VAR(game_phase, config::gamecontroller::game::phase::t, config::gamecontroller::game::phase::normal)
ATOMIC_VAR(state, config::gamecontroller::state::t, config::gamecontroller::state::initial)
ATOMIC_VAR(set_play, config::gamecontroller::set_play::t, config::gamecontroller::set_play::none)
ATOMIC_VAR(first_half, u8, 1)
ATOMIC_VAR(kicking_team, u8, config::gamecontroller::color::blue)
ATOMIC_VAR(secs_remaining, i16, -1)
ATOMIC_VAR(secondary_time, i16, 0)
ATOMIC_VAR(team1, spl::TeamInfo, {})
ATOMIC_VAR(team2, spl::TeamInfo, {})
#if DEBUG
#endif // DEBUG
#undef ATOMIC_VAR

impure static
bool
game_over()
noexcept {
  return (state() == config::gamecontroller::state::finished) and not first_half();
}

static
void
parse(spl::GameControlData&& msg)
noexcept {
  // NOLINTBEGIN(cppcoreguidelines-macro-usage)
#define TYPECHECK(LVALUE, RVALUE) static_assert(std::is_same_v<decltype(LVALUE()), std::decay_t<decltype(msg.RVALUE)>>)
#if DEBUG
#define UPDATE_ATOMIC(LVALUE, RVALUE, PRINT) TYPECHECK(LVALUE, RVALUE); if (msg.RVALUE != internal::LVALUE().exchange(std::move(msg.RVALUE), std::memory_order_relaxed)) { debug_print(std::cout, #LVALUE " updated -> ", PRINT(internal::LVALUE().load(std::memory_order_relaxed))); }
#else // DEBUG
#define UPDATE_ATOMIC(LVALUE, RVALUE, PRINT) TYPECHECK(LVALUE, RVALUE); internal::LVALUE().store(std::move(msg.RVALUE), std::memory_order_relaxed);
#endif // DEBUG
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

} // namespace context

#endif // CONTEXT_VARIABLES_HPP
