/*
Corresponds to legacy/Player/run_main.lua.
Calls loop::update() every few milliseconds until it returns false (usually, the entire duration of a game).
TODO: see https://www.cppstories.com/2019/12/threading-loopers-cpp17/
*/

#include "src/ctx/context.hpp"

auto
main()
-> int {

  // Initialize context manager (==> wireless connection to GameController)
  auto context = ctx::Context<config::gamecontroller::competition::phase::playoff,
                              config::gamecontroller::competition::type::normal>{};

  // Exit
  return 0;
}
