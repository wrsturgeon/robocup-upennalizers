#include "context/loop.hpp"  // for context::loop::victor_frankenstein
#include <sys/resource.h>    // for setpriority, PRIO_PROCESS

int
main()
noexcept {

  // Instruct the OS to give this process highest priority
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdisabled-macro-expansion"
  assert_eq(0, ::setpriority(PRIO_PROCESS, 0, -20), "Couldn't set OS priority")
#pragma clang diagnostic pop

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
