// note that prologue.hpp is automatically prepended here

#include "fsm/body.hpp"

#include "context/loop.hpp"

extern "C" {
#include <sys/resource.h> // setpriority
}

int
main()
noexcept {

  // Instruct the OS to give this process highest priority
  assert_eq(0, ::setpriority(PRIO_PROCESS, 0, -20), "Couldn't set OS priority")

  // Start everything & block until the game is over
  context::loop::victor_frankenstein();

  // Exit
  return 0;
}

#if !DEBUG
// static_assert(noexcept(main()));
// static_assert(std::is_nothrow_invocable_v<decltype(main)>);
static_assert(noexcept(context::loop::victor_frankenstein()));
static_assert(std::is_nothrow_invocable_v<decltype(context::loop::victor_frankenstein)>);
#endif
