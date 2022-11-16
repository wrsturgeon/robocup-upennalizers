#ifndef CTX_LOOP_HPP
#define CTX_LOOP_HPP

#include "ctx/context.hpp"
#include "messaging/io.hpp"

#include "config/gamecontroller.hpp"

#include "concurrency/jthread.hpp"

#include <cstddef>  // std::size_t
#include <iostream> // std::cerr

namespace ctx {
namespace loop {
namespace internal {

pure
bool
parse(spl::GameControlData&& from_gc) noexcept
{
  try {
    if ((from_gc.version == config::packet::gamecontroller::send::version)
    and !strncmp(static_cast<char*>(from_gc.header), config::packet::gamecontroller::send::header, sizeof from_gc.header)
    ) {
      ::ctx::parse(std::move(from_gc)); // NOLINT(performance-move-const-arg)
      return true; // valid packet
  #if DEBUG || VERBOSE
    } else {
      char header[sizeof from_gc.header + 1];
      std::copy_n(static_cast<char*>(from_gc.header), sizeof from_gc.header, static_cast<char*>(header));
      header[sizeof from_gc.header] = '\0';
      std::cout << "Invalid packet received (probably nonsense: version " << +from_gc.version << " (should be " << +config::packet::gamecontroller::send::version << "), header \"" << static_cast<char*>(header) << "\" (should be \"" << config::packet::gamecontroller::send::header << "\"))\n";
  #endif
    }
  } catch (const std::exception& e) {
    std::cerr << "Exception in ctx::loop::parse: " << e.what() << std::endl;
    std::terminate();
  } catch (...) { std::terminate(); }
  return false; // invalid packet
}

static
void
hermeneutics() noexcept // https://youtu.be/rzXPyCY7jbs
{
  // Keep slamming our head into a wall until we get a valid packet from the GameController.

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

static
void
proselytize() noexcept
{
  // Yell at everyone until we get our message through to the GC.

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

// static
// void
// dialectics() noexcept
// {
//   // Communicate with teammates.
//   // TODO(wrsturgeon): implement
// }

// static
// void
// prayer() noexcept
// {
//   // Send our innermost unclean thoughts to God (i.e. debug info to our laptop).
//   // TODO(wrsturgeon): implement
// }

static
void
run() noexcept
{
  //%%%%%%%%%%%%%%%% Wait for the first valid packet from a GameController
#if DEBUG || VERBOSE
  try { std::cout << "Waiting for a GameController to open communication...\n"; } catch (std::exception const& e) { std::cerr << e.what() << std::endl; std::terminate(); } catch (...) { std::terminate(); }
#endif
  hermeneutics();
#if DEBUG || VERBOSE
  try { std::cout << "Got it!\n"; } catch (std::exception const& e) { std::cerr << e.what() << std::endl; std::terminate(); } catch (...) { std::terminate(); }
#endif

  //%%%%%%%%%%%%%%%% Loop until someone wins the game
  do { // while the game isn't over
    proselytize(); // -> GC
    // dialectics(); // <-> teammates
    // prayer();     // -> laptop
    hermeneutics(); // <- GC
  } while (not ::ctx::done()); // the sweet release of death
}

impure static
concurrency::we_have_std_jthread_at_home const&
thread() noexcept
{
  static concurrency::we_have_std_jthread_at_home const thread{[]{ run(); }}; // clang hasn't implemented std::jthread
  return thread;
}

} // namespace internal

[[gnu::always_inline]] inline static
void
victor_frankenstein() noexcept
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-result"
  internal::thread(); // don't need the return value; it's a static variable in the function we call
#pragma clang diagnostic pop
}

} // namespace loop
} // namespace ctx

#endif // CTX_LOOP_HPP
