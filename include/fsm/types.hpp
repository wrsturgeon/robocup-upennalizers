#ifndef FSM_TYPES_HPP
#define FSM_TYPES_HPP

#include <atomic>        // for std::memory_order_relaxed, std::atomic
#include <concepts>      // for std::same_as
#include <fixed-string>  // for fixed::String

namespace fsm {

namespace internal {

template <fixed::String Group> struct event {/* empty */};
template <fixed::String Group> struct state {/* empty */};

template <fixed::String Group, fixed::String State, u8 guess = 0>
pure static
u8
state_id() {
  static_assert(guess < std::tuple_size_v<decltype(internal::state<Group>::all)>, "State not found (or before starting guess if nonzero)");
  if constexpr (!(State == std::get<guess>(internal::state<Group>::all))) {
    return state_id<Group, State, guess + 1>(); }
  return guess;
}

template <fixed::String Group> INLINE static void entry_fn(u8 from) noexcept;
template <fixed::String Group> INLINE static void exit_fn(u8 from) noexcept;

template <fixed::String Group, fixed::String Event> pure static u8 next_state(u8 from) noexcept;

} // namespace internal

template <fixed::String Group>
concept registered_group = requires {
  { internal::event<Group>::all };
  { internal::event<Group>::max } -> std::same_as<u8 const&>;
  { internal::state<Group>::all };
  { internal::state<Group>::max } -> std::same_as<u8 const&>;
  { internal::state<Group>::current } -> std::same_as<std::atomic<u8>&>;
};
template <fixed::String Group, fixed::String Event>
requires registered_group<Group>
INLINE static
void
transition() {
  u8 const from_id = internal::state<Group>::current.load(std::memory_order_relaxed);
  internal::exit_fn<Group>(from_id);
  u8 const to_id{internal::next_state<Group, Event>(from_id)};
  internal::state<Group>::current.store(to_id, std::memory_order_relaxed);
  internal::entry_fn<Group>(to_id);
}

} // namespace fsm

#endif // FSM_TYPES_HPP
