#ifndef CONTEXT_LOOP_HPP
#define CONTEXT_LOOP_HPP

#include "messaging/io.hpp"
#include "schopenhauer/resolve.hpp"

#include "context/variables.hpp"

#include "config/gamecontroller.hpp"

#include "concurrency/jthread.hpp"

#include <cstddef>  // std::size_t
#include <iostream> // std::cerr

namespace context {
namespace loop {
namespace internal {

// Receive an ostensible packet; if it's valid, parse it, update variables, and return true.
pure
bool
parse(spl::GameControlData&& from_gc)
noexcept {
  try {
    if ((from_gc.version == config::packet::gc::from::version)
    and !strncmp(static_cast<char*>(from_gc.header), config::packet::gc::from::header, sizeof from_gc.header)
    ) {
      ::context::parse(std::move(from_gc)); // NOLINT(performance-move-const-arg)
      return true; // valid packet
  #if DEBUG
    } else {
      char header[sizeof from_gc.header + 1];
      std::copy_n(static_cast<char*>(from_gc.header), sizeof from_gc.header, static_cast<char*>(header));
      header[sizeof from_gc.header] = '\0';
      debug_print(std::cerr, "Invalid packet received (probably nonsense: version ", +from_gc.version, " (should be ", +config::packet::gc::from::version, "), header \"", static_cast<char*>(header), "\" (should be \"", config::packet::gc::from::header, "\"))");
  #endif
    }
  } catch (const std::exception& e) {
    std::cerr << "Exception in context::loop::parse: " << e.what() << std::endl;
    std::terminate();
  } catch (...) { std::terminate(); }
  return false; // invalid packet
}

// Keep slamming our head into a wall until we get a valid packet from the GameController.
static
void
hermeneutics() // https://youtu.be/rzXPyCY7jbs
noexcept {
  do { // forces exceptions to start over rather than breaking out of the loop
    try { // msg::recv_from_gc() throws msg::error if #bytes received =/= sizeof spl::GameControlData
      do {} while (!parse(msg::recv_from_gc())); // loop until we get a valid packet or throw
      break; // and here is the sole exit point
    } catch (msg::error const& e) { // if we get an exception, try to print it out and try again
      try { std::cerr << e.what() << std::endl; } catch (...) { std::terminate(); } // if we can't print, everything is probably on fire
    } catch (std::exception const& e) { // non-messaging exceptions shouldn't try again (infinite loop: nothing changed)
      try { std::cerr << e.what() << std::endl; } catch (...) {/* below */}
      std::terminate();
    } catch (...) { std::terminate(); }
  } while (true);
}

// Yell at everyone until we get our message through to the GC.
static
void
proselytize()
noexcept {
  do { // until we successfully send our packets out
    try { // if sending fails
      msg::send_to_gc(); // update the GC so the audience can see how fucking cool we are
      break; // success: break the inner loop (second `do`)
    } catch (msg::error const& e) { // if sending fails but not horribly
      std::cerr << e.what() << std::endl;
    } catch (std::exception const& e) { // if something else fails (not likely to change by trying again)
      std::cerr << e.what() << std::endl;
      std::terminate();
    } catch (...) { std::terminate(); } // on fire
  } while (true); // until we send to GC
}

// // Communicate with teammates.
// static
// void
// dialectics() noexcept
// {
//   // TODO(wrsturgeon): implement
// }

// // Send our innermost unclean thoughts to God (i.e. debug info to our laptop).
// static
// void
// prayer() noexcept
// {
//   // TODO(wrsturgeon): implement
// }

// Block until receiving from GC, then immediately parse, send off, and block again, ad infinitum.
static
void
run()
noexcept {
  //%%%%%%%%%%%%%%%% Wait for the first valid packet from a GameController
  debug_print(std::cout, "Waiting for a GameController to open communication...");
  hermeneutics(); // Keep trying through any msg::error until a valid packet
  debug_print(std::cout, "Got it!");

  //%%%%%%%%%%%%%%%% Start a separate thread to resolve goals with estimated reality
  debug_print(std::cout, "Kickstarting resolution thread...");
  concurrency::we_have_std_jthread_at_home<schopenhauer::resolve/*, sit_down_so_we_don't_fall_over*/> const resolve_thread{};
  debug_print(std::cout, "Resolution thread started!");

  //%%%%%%%%%%%%%%%% Loop until someone wins the game
  do { // while the game isn't over
    proselytize(); // -> GC
    // dialectics(); // <-> teammates
    // prayer();     // -> laptop
    hermeneutics(); // <- GC
  } while (not ::context::gameover()); // the sweet release of death
}

} // namespace internal

// Blocks the calling thread
[[gnu::always_inline]] inline static
void
victor_frankenstein()
noexcept {
  internal::run();
}

} // namespace loop
} // namespace context

#endif // CONTEXT_LOOP_HPP
