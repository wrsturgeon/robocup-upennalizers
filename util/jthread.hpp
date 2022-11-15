#pragma once
// Clang hasn't implemented std::jthread yet

#include <thread> // std::thread

namespace util {

class mom_we_have_std_jthread_at_home {
  std::thread thread;
 public:
  template <typename F> explicit mom_we_have_std_jthread_at_home(F&& f) : thread{std::forward<F>(f)} {}
  mom_we_have_std_jthread_at_home(mom_we_have_std_jthread_at_home const&) = delete;
  mom_we_have_std_jthread_at_home(mom_we_have_std_jthread_at_home&&) = delete;
  auto operator=(mom_we_have_std_jthread_at_home const&) -> mom_we_have_std_jthread_at_home& = delete;
  auto operator=(mom_we_have_std_jthread_at_home&&) -> mom_we_have_std_jthread_at_home& = delete;
  ~mom_we_have_std_jthread_at_home() { thread.join(); }
};

} // namespace util
