/*
Corresponds to legacy/Player/run_main.lua.
Calls loop::update() every few milliseconds until it returns false (usually, the entire duration of a game).
TODO: see https://www.cppstories.com/2019/12/threading-loopers-cpp17/
*/

#include "src/loop/update.hpp"
#include "src/body/fsm.hpp"
#include "src/head/fsm.hpp"
#include "src/game/fsm.hpp"
#include "src/msg/udp.hpp"

#include "calibrated/metrics.hpp"

#include <thread>

auto
main()
-> int {

  // Fire up wireless connections
  auto zmqctx = zmq::context_t{1};
  auto udp_thread = std::thread{msg::udp::open_communication, zmqctx}; // Spawn in parallel and forget it until we get a message

  // Initialize FSMs
  auto body_fsm = body::FSM{};
  auto head_fsm = head::FSM{};
  auto game_fsm = game::FSM<config::gc::competition::phase::playoff,
                            config::gc::competition::type::normal>{};

  // Calls loop::update() every few milliseconds until it returns false
  auto now = std::chrono::high_resolution_clock::now();
  if (loop::start(body_fsm, head_fsm, game_fsm)) { do {
    std::this_thread::sleep_until(now += std::chrono::milliseconds{config::logic::update_freq_ms});
  } while (loop::update(body_fsm, head_fsm, game_fsm)); }

  // Exit
  return 0;
}
