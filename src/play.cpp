/*
Corresponds to legacy/Player/run_main.lua.
Calls loop::update() every few milliseconds until it returns false (usually, the entire duration of a game).
TODO: see https://www.cppstories.com/2019/12/threading-loopers-cpp17/
*/

#include "src/ctx/context.hpp"

#include <chrono>   // std::chrono::seconds
#include <iostream> // std::cout
#include <thread>   // std::this_thread::sleep_for

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

  // Sleep
  std::cout << "Sleeping...\n";
  std::this_thread::sleep_for(std::chrono::seconds{10});
  std::cout << "Burning the circular ruins...\n";

  // Exit
  return 0;
}
