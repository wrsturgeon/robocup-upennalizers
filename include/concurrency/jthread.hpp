#ifndef CONCURRENCY_JTHREAD_HPP
#define CONCURRENCY_JTHREAD_HPP

// clang hasn't implemented std::jthread yet

#include <thread> // std::thread

namespace concurrency {

class we_have_std_jthread_at_home {
  std::thread thread;
 public:
  template <typename F> explicit we_have_std_jthread_at_home(F&& f) : thread{std::forward<F>(f)} {}
  we_have_std_jthread_at_home(we_have_std_jthread_at_home const&) = delete;
  we_have_std_jthread_at_home(we_have_std_jthread_at_home&&) = delete;
  we_have_std_jthread_at_home& operator=(we_have_std_jthread_at_home const&) = delete;
  we_have_std_jthread_at_home& operator=(we_have_std_jthread_at_home&&) = delete;
  ~we_have_std_jthread_at_home() { thread.join(); }
};

} // namespace concurrency

#endif // CONCURRENCY_JTHREAD_HPP
