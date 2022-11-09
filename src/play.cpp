// C++ interpretation of legacy/Player/run_main.lua

#include "calibrated/metrics.hpp"
#include "src/loop/update.hpp"
#include "src/body/fsm.hpp"
#include "src/head/fsm.hpp"
#include "src/game/fsm.hpp"

#include <thread>

auto
main()
-> int {

  // Initialize FSMs
  auto body_fsm = body::FSM{};
  auto head_fsm = head::FSM{};
  auto game_fsm = game::FSM<config::protocol::gc::competition::phase::playoff,
                            config::protocol::gc::competition::type::normal>{};

  // Calls loop::update() every few milliseconds until it returns false
  auto now = std::chrono::high_resolution_clock::now();
  if (loop::start(body_fsm, head_fsm, game_fsm)) { do {
    std::this_thread::sleep_until(now += std::chrono::milliseconds{config::logic::update_freq_ms});
  } while (loop::update(body_fsm, head_fsm, game_fsm)); }

  // Exit
  return 0;
}
