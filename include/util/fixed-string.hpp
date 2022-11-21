#ifndef UTIL_FIXED_STRING_HPP
#define UTIL_FIXED_STRING_HPP

#include <algorithm> // std::copy_n, std::equal
#include <array>     // std::array
#include <cassert>   // assert
#include <concepts>  // std::integral
#include <utility>   // std::forward, std::move

namespace util {

template <std::size_t N>
pure static
std::array<char, N + 1>
arr_from_str(char const (&str)[N + 1])
noexcept {
  assert(str[N] == '\0');
  std::array<char, N + 1> arr; // NOLINT(cppcoreguidelines-pro-type-member-init)
  std::copy_n(static_cast<char const*>(str), N + 1, arr.begin());
  return arr;
}

template <std::size_t N>
struct FixedString { // NOLINT(altera-struct-pack-align)
  std::array<char, N + 1> arr; // NOLINT(misc-non-private-member-variables-in-classes)
  constexpr explicit FixedString() noexcept : arr{} {} // solely for constant expressions
  // NOLINTNEXTLINE(google-explicit-constructor)
  constexpr FixedString(char const (&str)[N + 1]) noexcept : arr{arr_from_str<N>(str)} {}
  constexpr explicit FixedString(std::array<char, N + 1>&& a) noexcept : arr{std::move(a)} {}
  constexpr explicit FixedString(char c) noexcept requires (N == 1) { arr[0] = c; arr[1] = '\0'; }
  pure char const* c_str() const noexcept { return arr.data(); }
};

//%%%%%%%%%%%%%%%% Deduction guides

FixedString(char) -> FixedString<1>;

template <std::size_t N> requires (N > 0) // can still work on the empty string "" since in that case N=1 (null-terminated)
FixedString(char const (&)[N]) -> FixedString<N - 1>;

//%%%%%%%%%%%%%%%% Non-member functions

template <std::size_t N, std::size_t M>
pure
bool
operator==(FixedString<N> const& lhs, FixedString<M> const& rhs)
noexcept {
  if constexpr (N != M) { return false; }
  return std::equal(lhs.arr.begin(), lhs.arr.end(), rhs.arr.begin());
}

template <std::size_t N, std::size_t M>
pure
FixedString<N + M>
operator+(FixedString<N> const& lhs, FixedString<M> const& rhs)
noexcept {
  FixedString<N + M> rtn{}; // sadly must be zero-initialized to use in constant expressions
  std::copy_n(lhs.arr.begin(), N, rtn.arr.begin());
  std::copy_n(rhs.arr.begin(), M, rtn.arr.begin() + N);
  rtn.arr[N + M] = '\0';
  return rtn;
}

template <std::size_t N, typename T>
requires requires (T const& t) { FixedString{t}; }
pure
decltype(auto)
operator+(FixedString<N> const& lhs, T const& rhs)
noexcept {
  return lhs + FixedString{rhs};
}

template <std::size_t N, typename T>
requires requires (T const& t) { FixedString{t}; }
pure
decltype(auto)
operator+(T const& lhs, FixedString<N> const& rhs)
noexcept {
  return FixedString{lhs} + rhs;
}

template <std::unsigned_integral auto x>
inline constexpr u8 log10{x ? 1 + log10<x / 10U> : 0};

template <std::unsigned_integral auto x>
pure static
std::array<char, log10<x> + 2>
array_itoa()
noexcept {
  std::array<char, log10<x> + 2> arr{};
  arr[log10<x> + 1] = '\0';
  u8 i{log10<x>};
  for (auto n{x}; n > 0; n /= 10U) { arr[i--] = static_cast<char>(n % 10U + '0'); }
  return arr;
}

template <std::unsigned_integral auto x>
inline constexpr FixedString<log10<x> + 1> fixed_itoa{array_itoa<x>()};

} // namespace util

#endif // UTIL_FIXED_STRING_HPP
