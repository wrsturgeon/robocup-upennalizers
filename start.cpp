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
