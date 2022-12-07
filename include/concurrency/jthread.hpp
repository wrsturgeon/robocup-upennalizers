#ifndef CONCURRENCY_JTHREAD_HPP
#define CONCURRENCY_JTHREAD_HPP

// clang hasn't implemented std::jthread yet

#include <fixed-string>  // for fixed::String

#include "concurrency/threadable.hpp" // IWYU pragma: keep

extern "C" {
#include <pthread.h>     // for pthread_attr_destroy, pthread_attr_init, pthread_attr_setdetachstate, pthread_attr_setinheritsched, pthread_attr_setschedpolicy, pthread_join, pthread_t, PTHREAD_CREATE_JOINABLE, PTHREAD_EXPLICIT_SCHED, SCHED_RR, pthread_attr_t, pthread_create
}

namespace concurrency {

template <fixed::String Name, threadable auto atentry, threadable auto atexit = []() noexcept {}>
class we_have_std_jthread_at_home {
  pthread_t _id;
 public:
  we_have_std_jthread_at_home() noexcept;
  we_have_std_jthread_at_home(we_have_std_jthread_at_home const&) = delete;
  we_have_std_jthread_at_home(we_have_std_jthread_at_home&&) = delete;
  we_have_std_jthread_at_home& operator=(we_have_std_jthread_at_home const&) = delete;
  we_have_std_jthread_at_home& operator=(we_have_std_jthread_at_home&&) = delete;
  ~we_have_std_jthread_at_home();
  [[gnu::always_inline]] inline void set_priority(int priority) noexcept;
};

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-parameter"
template <fixed::String Name, threadable auto atentry, threadable auto atexit>
we_have_std_jthread_at_home<Name, atentry, atexit>::
we_have_std_jthread_at_home()
noexcept
: _id{[]{
  pthread_attr_t attr;
  assert_eq(0, pthread_attr_init(&attr), "Couldn't default-initialize thread attributes")
  assert_eq(0, pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_JOINABLE), "Couldn't set thread detach state to joinable")
  assert_eq(0, pthread_attr_setschedpolicy(&attr, SCHED_RR), "Couldn't set thread scheduling policy to round-robin")
  assert_eq(0, pthread_attr_setinheritsched(&attr, PTHREAD_EXPLICIT_SCHED), "Couldn't set thread scheduling inheritance to explicit")
  pthread_t rtn{};
  assert_eq(0, pthread_create(&rtn, &attr, [](void* arg) -> void* { // NOLINT(misc-unused-parameters)
    print_concurrency(Name, " thread started; calling atentry");
    atentry();
    print_concurrency(Name, " thread atentry returned; calling atexit");
    atexit();
    print_concurrency(Name, " thread atexit returned; done");
    return nullptr;
  }, nullptr), "Couldn't create thread")
  assert_eq(0, pthread_attr_destroy(&attr), "Couldn't destroy thread attributes")
  return rtn;
}()} {}
#pragma clang diagnostic pop

template <fixed::String Name, threadable auto atentry, threadable auto atexit>
we_have_std_jthread_at_home<Name, atentry, atexit>::~we_have_std_jthread_at_home() {
  print_concurrency(Name, " thread dtor: joining...");
  assert_eq(0, pthread_join(_id, nullptr), "Couldn't join thread")
}

} // namespace concurrency

#endif // CONCURRENCY_JTHREAD_HPP
