#ifndef CTX_CONTEXT_FWD_HPP
#define CTX_CONTEXT_FWD_HPP

#include "config/gamecontroller.hpp"
#include "config/spl-message.hpp"

#include <atomic> // std::atomic

namespace ctx {

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

// static spl::Message make_spl_message();
static spl::GameControlReturnData make_gc_message();
static void parse(spl::GameControlData&&) noexcept;
impure static bool done() noexcept { return (state() == config::gamecontroller::state::finished) and not first_half(); }

} // namespace ctx

#endif // CTX_CONTEXT_FWD_HPP
