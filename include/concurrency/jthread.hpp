#ifndef CONCURRENCY_JTHREAD_HPP
#define CONCURRENCY_JTHREAD_HPP

// clang hasn't implemented std::jthread yet

#include <concepts>    // std::invocable
#include <thread>      // std::thread
#include <type_traits> // std::is_nothrow_invocable_v

namespace concurrency {

template <std::invocable<> auto atentry, std::invocable<> auto atexit = []() noexcept {}>
requires std::is_nothrow_invocable_v<decltype(atentry)> and std::is_nothrow_invocable_v<decltype(atexit)>
class we_have_std_jthread_at_home {
  std::thread thread;
 public:
  we_have_std_jthread_at_home() noexcept : thread{atentry} {}
  we_have_std_jthread_at_home(we_have_std_jthread_at_home const&) = delete;
  we_have_std_jthread_at_home(we_have_std_jthread_at_home&&) = delete;
  we_have_std_jthread_at_home& operator=(we_have_std_jthread_at_home const&) = delete;
  we_have_std_jthread_at_home& operator=(we_have_std_jthread_at_home&&) = delete;
  ~we_have_std_jthread_at_home();
};

template <std::invocable<> auto atentry, std::invocable<> auto atexit>
requires std::is_nothrow_invocable_v<decltype(atentry)> and std::is_nothrow_invocable_v<decltype(atexit)>
we_have_std_jthread_at_home<atentry, atexit>::~we_have_std_jthread_at_home() {
  debug_print(std::cout, "jthread dtor: running atexit...");
  atexit();
  debug_print(std::cout, "jthread dtor: joining...");
  thread.join();
}

} // namespace concurrency

#endif // CONCURRENCY_JTHREAD_HPP
