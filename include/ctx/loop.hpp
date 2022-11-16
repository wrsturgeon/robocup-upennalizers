#ifndef CTX_LOOP_HPP
#define CTX_LOOP_HPP

#include "ctx/loop-fwd.hpp"

#include "ctx/context-fwd.hpp"
#include "msg/io.hpp"

#include <cstddef>     // std::size_t

#if DEBUG || VERBOSE
#include <iostream> // std::cout
#endif

namespace ctx {
namespace loop {

static
void
run() noexcept
{
#if DEBUG || VERBOSE
  try { std::cout << "Waiting for a GameController to open communication...\n"; } catch (std::exception const& e) { std::cerr << e.what() << '\n'; } catch (...) { std::terminate(); }
#endif
  parse([]{ do { try { return msg::recv_from_gc(); } catch (std::exception const& e) { std::cerr << e.what() << '\n'; } catch (...) { std::terminate(); } } while (true); }());

  // Continue until someone wins the game
  do {
    do { try { msg::send_to_gc(); break; } catch (std::exception const& e) { std::cerr << e.what() << '\n'; } catch (...) { std::terminate(); } } while (true);
    // msg::send_to_team(static_cast<spl::Message>(context));
    parse(msg::recv_from_gc()); // blocking
  } while (not ::ctx::done());
}

INLINE
void
parse(spl::GameControlData&& from_gc) noexcept
{
  try {
    if ((from_gc.version == config::udp::gamecontroller::send::version)
    and !strncmp(static_cast<char*>(from_gc.header), config::udp::gamecontroller::send::header, sizeof from_gc.header)
    ) {
      ::ctx::parse(std::move(from_gc)); // NOLINT(performance-move-const-arg)
  #if DEBUG || VERBOSE
    } else {
      char header[sizeof from_gc.header + 1];
      std::copy_n(static_cast<char*>(from_gc.header), sizeof from_gc.header, static_cast<char*>(header));
      header[sizeof from_gc.header] = '\0';
      std::cout << "Invalid packet received (probably nonsense: version " << +from_gc.version << " (should be " << +config::udp::gamecontroller::send::version << "), header \"" << static_cast<char*>(header) << "\" (should be \"" << config::udp::gamecontroller::send::header << "\"))\n";
  #endif
    }
  } catch (const std::exception& e) {
    std::cerr << "Exception in ctx::loop::parse: " << e.what() << '\n';
  } catch (...) { std::terminate(); }
}

} // namespace loop
} // namespace ctx

#endif // CTX_LOOP_HPP
