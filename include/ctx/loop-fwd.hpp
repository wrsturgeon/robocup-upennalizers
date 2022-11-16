#ifndef CTX_LOOP_FWD_HPP
#define CTX_LOOP_FWD_HPP

#include "config/gamecontroller.hpp"

#include "util/jthread.hpp"

#include <chrono>     // std::chrono::milliseconds

namespace ctx {
namespace loop {

static void run() noexcept;
INLINE void parse(spl::GameControlData&& from_gc) noexcept;

inline constexpr std::chrono::milliseconds update_period{config::logic::update_period_ms};

impure static
std::chrono::steady_clock::time_point const&
next_update() noexcept
{
  static std::chrono::steady_clock::time_point tm{std::chrono::steady_clock::now()};
  return tm += update_period;
}

impure static
util::we_have_std_jthread_at_home const&
thread() noexcept
{
  static util::we_have_std_jthread_at_home const thread{[]{ run(); }}; // clang hasn't implemented std::jthread
  return thread;
}

} // namespace loop
} // namespace ctx

#endif // CTX_LOOP_FWD_HPP
