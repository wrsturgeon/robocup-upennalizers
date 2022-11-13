/*
Corresponds to legacy/Player/run_main.lua.
Calls loop::update() every few milliseconds until it returns false (usually, the entire duration of a game).
TODO: see https://www.cppstories.com/2019/12/threading-loopers-cpp17/
*/

#include "src/ctx/context.hpp"

#include <chrono>   // std::chrono::seconds
#include <thread>   // std::this_thread::sleep_for

#if DEBUG
#include <iostream> // std::cout
#endif

auto
main()
-> int {

  // Initialize context manager (==> wireless connection to GameController)
  auto context = ctx::Context<config::gamecontroller::competition::phase::playoff,
                              config::gamecontroller::competition::type::normal>{};
  // now we have two threads going:
  //   - the one we're on now, and
  //   - the communication thread (opened in parallel above)
  //       - ctx::Context{} -> ctx::Loop{} -> std::thread{}

  // Exit
  return 0;
}
