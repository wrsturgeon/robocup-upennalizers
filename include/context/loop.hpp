#ifndef CONTEXT_LOOP_HPP
#define CONTEXT_LOOP_HPP

#include <algorithm>                        // for std::copy_n
#include <exception>                        // for std::exception
#include <fixed-string>                     // for fixed::String
#include <utility>                          // for std::move

#include "concurrency/jthread.hpp"          // for concurrency::we_have_std_jthread_at_home
#include "concurrency/thread-priority.hpp"  // for concurrency::min_priority, concurrency::prioritize
#include "config/gamecontroller.hpp"        // for spl::GameControlData
#include "config/ip.hpp"                    // for config::ip::address, config::ip::port::from, config::ip::port::to
#include "config/packet.hpp"                // for config::packet::gc::from::header, config::packet::gc::from::version
#include "context/variables.hpp"            // for context::game_over, context::parse
#include "messaging/io.hpp"                 // for msg::recv_from_gc, msg::send_to_gc
#include "schopenhauer/resolve.hpp"         // for schopenhauer::resolve

extern "C" {
#include <pthread.h>                        // for pthread_self
#include <string.h>                         // for strncmp
}

namespace context {
namespace loop {
namespace internal {

// Receive an ostensible packet; if it's valid, parse it, update variables, and return true.
pure
bool
parse(spl::GameControlData&& from_gc)
noexcept {
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
    print_error("Invalid packet received (probably nonsense: version ", +from_gc.version, " (should be ", +config::packet::gc::from::version, "), header \"", static_cast<char*>(header), "\" (should be \"", config::packet::gc::from::header, "\"))");
#endif
  }
  return false; // invalid packet
}

// Keep slamming our head into a wall until we get a valid packet from the GameController.
static
void
hermeneutics() // https://youtu.be/rzXPyCY7jbs
noexcept {
  do {} while (!parse(msg::recv_from_gc()));
}

// Yell at everyone until we get our message through to the GC.
static
void
proselytize()
noexcept {
  msg::send_to_gc(); // repeatedly calls an internal function that is failure-aware until it succeeds
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
  print_io("Waiting for communication on port ", config::ip::port::from<"GameController">, "...");
  hermeneutics(); // Keep trying through any msg::error until we get a valid packet

  //%%%%%%%%%%%%%%%% Start a separate thread to resolve goals with estimated reality
  concurrency::we_have_std_jthread_at_home<"Resolution", schopenhauer::resolve/*, sit_down_so_we_don't_fall_over*/> const resolution{}; // NOLINT(cppcoreguidelines-init-variables)

  //%%%%%%%%%%%%%%%% Lower this thread's priority (since it's now just for communication)
  // Note that the GameController will occasionally show the robot's communication flickering;
  //   this means the robot is "thinking hard" on another thread and hasn't checked this one for more than a second.
  // This shouldn't generally matter, and it buys us time on other, more important threads,
  //   BUT it also slows our reception of information from the GC, so if we can't detect events, we may be less informed.
  // If this robot ever _fully disconnects_, we should probably increase the priority below.
  concurrency::prioritize(::pthread_self(), concurrency::min_priority());

  //%%%%%%%%%%%%%%%% Just so, if we fucked up the IP, we know
  print_io("Opening unicast communication to ", config::ip::address<"GameController">, " on port ", config::ip::port::to<"GameController">, "...");

  //%%%%%%%%%%%%%%%% Loop until someone wins the game
  do { // while the game isn't over
    proselytize(); // -> GC
    // dialectics(); // <-> teammates
    // prayer();     // -> laptop
    hermeneutics(); // <- GC
  } while (not ::context::game_over()); // the sweet release of death
}

} // namespace internal

// Blocks the calling thread
[[gnu::always_inline]] inline static
void
victor_frankenstein()
noexcept {
  internal::run(); // blocking
}

} // namespace loop
} // namespace context

#endif // CONTEXT_LOOP_HPP
