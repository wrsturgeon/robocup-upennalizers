#pragma once

#include "src/ctx/context-fwd-fwd.hpp"
#include "src/msg/io.hpp"

#include "config/gamecontroller.hpp"
#include "config/wireless.hpp"

#include <atomic>     // std::atomic
#include <chrono>     // std::chrono::milliseconds
#include <functional> // std::bind
#include <thread>     // std::thread

namespace ctx {

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpadded"
template <config::gamecontroller::competition::phase::t CompetitionPhase,
          config::gamecontroller::competition::type ::t CompetitionType>
class Loop {
  using self_t = Loop<CompetitionPhase, CompetitionType>;
  static constexpr std::chrono::milliseconds update_period{config::logic::update_period_ms};
  std::chrono::steady_clock::time_point wait_until{std::chrono::steady_clock::now()};
  Context<CompetitionPhase, CompetitionType>& context;
  std::atomic<bool> continue_looping{true};
  std::thread thread{std::bind(&self_t::operator(), this)};
#if DEBUG
  static std::atomic<bool> any_loop_started;
#endif
  auto operator()() noexcept -> void;
  INLINE auto parse(std::optional<spl::GameControlData> const& from_gc) noexcept -> void;
 public:
  Loop(Context<CompetitionPhase, CompetitionType>& context_ref) noexcept : context{context_ref} { assert(!any_loop_started.exchange(true)); }
  Loop(Loop const&) = delete;
  Loop(Loop&&) = delete;
  auto operator=(Loop const&) -> Loop& = delete;
  auto operator=(Loop&&) -> Loop& = delete;
  ~Loop() noexcept { continue_looping.store(false); thread.join(); }
};
#pragma clang diagnostic pop

} // namespace ctx
