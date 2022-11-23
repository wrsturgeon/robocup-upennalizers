#ifndef FSM_REGISTER_HPP
#define FSM_REGISTER_HPP

// this DOES NOT introduce any string processing at runtime
// we use compile-time strings to stand in for events/states that are then entirely optimized away

#include "fsm/types.hpp"

#include <fixed-string>

namespace fsm {
namespace internal {
template <typename... Args>
pure static
decltype(auto)
make_tuple(Args&&... args) {
  return ::std::make_tuple(fixed::String{args}...);
}
} // namespace internal
} // namespace fsm

// NOLINTBEGIN(cppcoreguidelines-macro-usage)

#define REGISTER_FSM_EVENTS(GROUP, ...)                          \
template <> struct ::fsm::internal::event<#GROUP> {              \
  static constexpr decltype(auto) all =                          \
    ::fsm::internal::make_tuple(__VA_ARGS__);                    \
  static_assert(std::tuple_size_v<decltype(all)>);               \
  static_assert(std::tuple_size_v<decltype(all)> <= 256);        \
  static constexpr u8 max{std::tuple_size_v<decltype(all)> - 1}; \
}; // `max` above, not `size`, b/c 256 elements is a valid case, but 0 is not

// NOLINTBEGIN(cppcoreguidelines-avoid-non-const-global-variables)
#define REGISTER_FSM_STATES(GROUP, ...)                          \
template <> struct ::fsm::internal::state<#GROUP> {              \
  static constexpr decltype(auto) all =                          \
    ::fsm::internal::make_tuple(__VA_ARGS__);                    \
  static_assert(std::tuple_size_v<decltype(all)>);               \
  static_assert(std::tuple_size_v<decltype(all)> <= 256);        \
  static constexpr u8 max{std::tuple_size_v<decltype(all)> - 1}; \
  static std::atomic<u8> current;                                \
}; ::std::atomic<u8> (::fsm::internal::state<#GROUP>::current){0};
// NOLINTEND(cppcoreguidelines-avoid-non-const-global-variables)

#define REGISTER_FSM_TRANSITION_EVENT(GROUP, EVENT, ...) \
template <>                                              \
pure                                                     \
u8                                                       \
(::fsm::internal::next_state<#GROUP, #EVENT>)(u8 from)   \
noexcept {                                               \
  constexpr fixed::String group{#GROUP};                 \
  switch (from) {                                        \
    __VA_ARGS__                                          \
    default:                                             \
      debug_print(std::cerr,                             \
            "No transition found; "                      \
            "returning original state");                 \
      return from;                                       \
  }                                                      \
}

#define TRANSITION(FROM, TO)                        \
    case ::fsm::internal::state_id<group, #FROM>(): \
      return ::fsm::internal::state_id<group, #TO>();

#define VERIFY_FSM_REGISTRATION(GROUP) static_assert(fsm::registered_group<#GROUP>);

// NOLINTEND(cppcoreguidelines-macro-usage)

#endif // FSM_REGISTER_HPP
