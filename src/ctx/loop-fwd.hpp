#pragma once

#include "config/gamecontroller.hpp"

#include "util/jthread.hpp"

#include <chrono>     // std::chrono::milliseconds

namespace ctx {
namespace loop {

static auto run() noexcept -> void;
INLINE auto parse(spl::GameControlData&& from_gc) noexcept -> void;

inline constexpr auto update_period = std::chrono::milliseconds{config::logic::update_period_ms};
static auto wait_until = std::chrono::steady_clock::time_point{std::chrono::steady_clock::now()};
static auto thread = util::mom_we_have_std_jthread_at_home{[]{ run(); }}; // clang hasn't implemented std::jthread

} // namespace loop
} // namespace ctx
