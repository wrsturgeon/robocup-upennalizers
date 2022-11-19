// note that prologue.hpp is automatically prepended here

#include "context/loop.hpp"

int
main()
noexcept {

  // Function that starts everything & blocks until the game is over
  context::loop::victor_frankenstein();

  // Exit
  return 0;
}

#ifdef NDEBUG
static_assert(noexcept(main()));
static_assert(std::is_nothrow_invocable_v<decltype(main)>);
#endif
