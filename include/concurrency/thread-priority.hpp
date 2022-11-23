#ifndef CONCURRENCY_THREAD_PRIORITY_HPP
#define CONCURRENCY_THREAD_PRIORITY_HPP

// Not anywhere in the C++ standard since describing its portable behavior would be a nightmare (thanks, Windows!)

#include "concurrency/jthread.hpp"

#include <fixed-string>

extern "C" {
#include <pthread.h> // pthread_setschedparam, pthread_self, ...
#include <sched.h>   // sched_param, sched_yield, SCHED_RR, ...
}

namespace concurrency {

[[gnu::always_inline]] inline
void
yield()
noexcept {
  ::sched_yield();
}

impure static
int
min_priority()
noexcept {
  static int const value{sched_get_priority_min(SCHED_RR)};
  return value;
}

impure static
int
max_priority()
noexcept {
  static int const value{sched_get_priority_max(SCHED_RR)};
  return value;
}

[[gnu::always_inline]] inline
void
prioritize(pthread_t thread, int priority)
noexcept {
#if DEBUG
  assert_eq(false, priority < min_priority(), "Trying to set a thread priority below the system minimum")
  assert_eq(false, priority > max_priority(), "Trying to set a thread priority above the system maximum")
#endif // DEBUG
  sched_param const param{.sched_priority = priority};
  assert_eq(0, pthread_setschedparam(thread, SCHED_RR, &param), "Couldn't set thread priority")
}

// https://man7.org/linux/man-pages/man7/sched.7.html
template <fixed::String Name, threadable auto atentry, threadable auto atexit>
[[gnu::always_inline]] inline
void
we_have_std_jthread_at_home<Name, atentry, atexit>::
set_priority(int priority)
noexcept {
  prioritize(_id, priority);
}

} // namespace concurrency

#endif // CONCURRENCY_THREAD_PRIORITY_HPP
