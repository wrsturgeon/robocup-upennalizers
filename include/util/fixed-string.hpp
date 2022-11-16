#ifndef UTIL_FIXED_STRING_HPP
#define UTIL_FIXED_STRING_HPP

#include <algorithm> // std::copy_n, std::equal

namespace util {

template <std::size_t N> requires (N > 0)
struct FixedString { // NOLINT(altera-struct-pack-align)
  char arr[N]; // NOLINT(misc-non-private-member-variables-in-classes)
  // NOLINTNEXTLINE(google-explicit-constructor,cppcoreguidelines-pro-type-member-init)
  INLINE FixedString(char const (&str)[N]) noexcept;
  pure char const* c_str() const noexcept { return static_cast<char const*>(arr); }
  template <std::size_t M> requires (M > 0) pure bool operator==(FixedString const& other) const noexcept;
};

// Deduction guide
template <std::size_t N>
FixedString(char const (&)[N])
-> FixedString<N>;

template <std::size_t N> // NOLINT(cppcoreguidelines-pro-type-member-init)
requires (N > 0)
INLINE FixedString<N>::
FixedString(char const (&str)[N])
noexcept {
  std::copy_n(static_cast<char const*>(str), N - 1, static_cast<char*>(arr));
  arr[N - 1] = '\0';
}

template <std::size_t N>
requires (N > 0)
template <std::size_t M>
requires (M > 0)
pure
bool
FixedString<N>::
operator==(FixedString const& other)
const noexcept {
  if constexpr (N != M) { return false; }
  return std::equal(arr, arr + N, other.arr);
}

template <std::size_t N, std::size_t M>
requires ((N > 0) and (M > 0))
impure
std::string
operator+(char const (&lhs)[N], FixedString<M> const& rhs) {
  std::string str{};
  str.reserve(N + M - 1);
  str.append(static_cast<char const*>(lhs    ), N - 1);
  str.append(static_cast<char const*>(rhs.arr), M - 1);
  return str;
}

} // namespace util

#endif // UTIL_FIXED_STRING_HPP
