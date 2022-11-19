#ifndef CONCURRENCY_THREAD_PRIORITY_HPP
#define CONCURRENCY_THREAD_PRIORITY_HPP

// Not anywhere in the C++ standard since describing its portable behavior would be a nightmare
// Thanks, Microsoft! :D   *jumps out window*

#include "concurrency/error.hpp"
#include "concurrency/jthread.hpp"

extern "C" {
#include <pthread.h> // pthread_setschedparam
#include <sched.h>   // sched_param
}

namespace concurrency {

INLINE void prioritize(pthread_t thread, int priority) noexcept {
#ifndef NDEBUG
  if (priority < sched_get_priority_min(SCHED_FIFO) || priority > sched_get_priority_max(SCHED_FIFO)) {
    throw error{
      "invalid priority " + std::to_string(priority)
      + "; this OS supports values on ["
      + std::to_string(sched_get_priority_min(SCHED_FIFO)) + ".."
      + std::to_string(sched_get_priority_max(SCHED_FIFO)) + "]"};
  }
#endif // NDEBUG
  sched_param param;
  param.sched_priority = priority;
  pthread_setschedparam(thread, SCHED_OTHER, &param);
}

// https://man7.org/linux/man-pages/man7/sched.7.html
template <threadable auto atentry, threadable auto atexit>
void we_have_std_jthread_at_home<atentry, atexit>::set_priority(int priority) noexcept {
  pthread_setschedparam(thread.native_handle(), SCHED_FIFO, {priority});
  thread.
}

} // namespace concurrency

#endif // CONCURRENCY_THREAD_PRIORITY_HPP
