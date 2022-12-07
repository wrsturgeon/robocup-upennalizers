#ifndef CONCURRENCY_THREADABLE_HPP
#define CONCURRENCY_THREADABLE_HPP

#include <functional>  // for std::invoke_result_t
#include <utility>     // for std::declval

template <typename F>
concept threadable = (noexcept(std::declval<F>()())
  and std::is_nothrow_invocable_v<F>
  and std::is_same_v<void, std::invoke_result_t<F>>);

#endif // CONCURRENCY_THREADABLE_HPP
