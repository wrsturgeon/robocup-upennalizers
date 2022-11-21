#ifndef UTIL_CXSTR_HPP
#define UTIL_CXSTR_HPP

#include <array>       // std::array
#include <cassert>     // assert
#include <cstddef>     // std::size_t
#include <sys/types.h> // ssize_t

namespace cx {

template <char key, std::size_t strlen, typename T>
requires (sizeof(T) == 1)
pure static
ssize_t
strchr(T const (&str)[strlen], std::size_t const start = 0)
noexcept {
  for (std::size_t i{start}; i < strlen; ++i) {
    if (static_cast<char>(str[i]) == key) { return static_cast<ssize_t>(i); }
  }
  return -1;
}

template <char key, std::size_t strlen, typename T>
requires (sizeof(T) == 1)
pure static
ssize_t
strchrrev(T const (&str)[strlen], std::size_t const start = strlen - 1)
noexcept {
  for (std::size_t i{start}; i; --i) {
    if (static_cast<char>(str[i]) == key) { return static_cast<ssize_t>(i); }
  }
  return -1;
}

template <std::size_t strlen, typename T>
requires (sizeof(T) == 1)
pure static
std::size_t
unsigned_atoi(T const (&str)[strlen], std::size_t const i0 = 0, std::size_t const i1 = strlen)
noexcept {
  std::size_t result{0};
  for (std::size_t i{i0}; i < i1; ++i) {
    assert(static_cast<char>(str[i]) >= '0' and static_cast<char>(str[i]) <= '9');
    result *= 10;
    result += static_cast<char>(str[i] - '0');
  }
  return result;
}

template <bool null_included, std::size_t lhs_strlen, std::size_t rhs_strlen, typename T_lhs, typename T_rhs>
requires ((sizeof(T_lhs) == 1) and (sizeof(T_rhs) == 1))
pure static
bool
substreq(T_lhs const (&lhs)[lhs_strlen], T_rhs const (&rhs)[rhs_strlen], std::size_t const lhs_start)
noexcept {
  for (std::size_t i{0}; i < rhs_strlen - 1 + null_included; ++i) {
    if (static_cast<char>(lhs[lhs_start + i]) != static_cast<char>(rhs[i])) { return false; }
  }
  return true;
}

template <bool null_included, std::size_t lhs_strlen, std::size_t rhs_strlen, typename T_lhs, typename T_rhs>
requires ((sizeof(T_lhs) == 1) and (sizeof(T_rhs) == 1))
pure static
bool
substreq(std::array<T_lhs, lhs_strlen> const& lhs, T_rhs const (&rhs)[rhs_strlen], std::size_t const lhs_start)
noexcept {
  for (std::size_t i{0}; i < rhs_strlen - 1 + null_included; ++i) {
    if (static_cast<char>(lhs[lhs_start + i]) != static_cast<char>(rhs[i])) { return false; }
  }
  return true;
}

} // namespace cx

#endif // UTIL_CXSTR_HPP
