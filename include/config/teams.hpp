#ifndef CONFIG_TEAMS_HPP
#define CONFIG_TEAMS_HPP

// Parse the GameController's source code at compile time
// specifically, ext/GameController/resources/config/spl/teams.cfg

#include "xxd/gc_team_cfg.hpp"

#include "util/cxstr.hpp"

#include <algorithm>   // std::copy_n, std::min
#include <array>       // std::array
#include <cassert>     // assert
#include <cstddef>     // std::size_t
#include <iostream>    // std::cerr
#include <utility>     // std::pair
#include <vector>      // std::vector

extern "C" {
#include <sys/types.h> // ssize_t
}

namespace config {
namespace gamecontroller {
namespace team {

namespace internal {

//%%%%%%%%%%%%%%%% Parsing the GameController's source code at compile time

// If you get an error that `__assert_rtn` can't be called in a constant expression, that means the assertion is failing
inline constexpr u8 max_number{[]{
  ssize_t const eqidx{cx::strchrrev<'='>(::xxd::gc_team_cfg)};
  assert(eqidx != -1); // NOLINT(misc-static-assert) // ==> no '='
  ssize_t const nlidx{cx::strchrrev<'\n'>(::xxd::gc_team_cfg, static_cast<std::size_t>(eqidx) - 1)};
  assert(nlidx != -1); // NOLINT(misc-static-assert) // ==> no newline before the last '='
  return cx::unsigned_atoi(::xxd::gc_team_cfg, nlidx + 1, eqidx);
}()};

// If you get an error that `__assert_rtn` can't be called in a constant expression, that means the assertion is failing
inline constexpr std::size_t all_names_len{[]{
  ssize_t eqidx{cx::strchr<'='>(::xxd::gc_team_cfg)};
  assert(eqidx != -1); // NOLINT(misc-static-assert) // ==> no '='
  ssize_t nlidx{cx::strchr<'\n'>(::xxd::gc_team_cfg, static_cast<std::size_t>(eqidx) + 1)};
  assert(nlidx != -1); // NOLINT(misc-static-assert) // ==> no newline after the first '='
  ssize_t cmidx{cx::strchr<','>(::xxd::gc_team_cfg, static_cast<std::size_t>(eqidx) + 1)};
  assert(cmidx != -1); // NOLINT(misc-static-assert) // ==> no comma after the first newline
  ssize_t ntidx{(cmidx == -1) ? nlidx : std::min(nlidx, cmidx)};
  assert(ntidx > eqidx); // NOLINT(misc-static-assert) // ==> something probably internal has gone horribly wrong
  std::size_t sum{static_cast<std::size_t>(ntidx) - eqidx}; // would be ...-1 but we add a null terminator so they cancel out
  while (-1 != (eqidx = cx::strchr<'='>(::xxd::gc_team_cfg, static_cast<std::size_t>(nlidx) + 1))) {
    nlidx = cx::strchr<'\n'>(::xxd::gc_team_cfg, static_cast<std::size_t>(eqidx) + 1);
    assert(nlidx != -1); // NOLINT(misc-static-assert) // ==> unmatched '=' (without a newline afterward)
    cmidx = cx::strchr<','>(::xxd::gc_team_cfg, static_cast<std::size_t>(eqidx) + 1);
    // actually fine if we don't have a comma afterward: they seem to be optional
    ntidx = (cmidx == -1) ? nlidx : std::min(nlidx, cmidx);
    assert(ntidx > eqidx); // NOLINT(misc-static-assert) // ==> something probably internal has gone horribly wrong
    sum += static_cast<std::size_t>(ntidx) - eqidx; // would be ...-1 but we add a null terminator so they cancel out
  }
  return sum;
}()};

// Contiguous array separated by null terminators
inline constexpr std::array<char, all_names_len> all_names{[]{
  std::array<char, all_names_len> rtn; // NOLINT(cppcoreguidelines-pro-type-member-init)
  std::size_t i{0};
  ssize_t eqidx{cx::strchr<'='>(::xxd::gc_team_cfg)};
  ssize_t nlidx{cx::strchr<'\n'>(::xxd::gc_team_cfg, static_cast<std::size_t>(eqidx))};
  ssize_t cmidx{cx::strchr<','>(::xxd::gc_team_cfg, static_cast<std::size_t>(eqidx))};
  ssize_t ntidx{(cmidx == -1) ? nlidx : std::min(nlidx, cmidx)};
  std::copy_n(&::xxd::gc_team_cfg[eqidx + 1], static_cast<std::size_t>(ntidx) - (eqidx + 1), &rtn[i]);
  i += static_cast<std::size_t>(ntidx) - eqidx;
  rtn[i - 1] = '\0';
  while (-1 != (eqidx = cx::strchr<'='>(::xxd::gc_team_cfg, static_cast<std::size_t>(nlidx) + 1))) {
    nlidx = cx::strchr<'\n'>(::xxd::gc_team_cfg, static_cast<std::size_t>(eqidx));
    cmidx = cx::strchr<','>(::xxd::gc_team_cfg, static_cast<std::size_t>(eqidx));
    ntidx = (cmidx == -1) ? nlidx : std::min(nlidx, cmidx);
    std::copy_n(&::xxd::gc_team_cfg[eqidx + 1], static_cast<std::size_t>(ntidx) - (eqidx + 1), &rtn[i]);
    i += static_cast<std::size_t>(ntidx) - eqidx;
    rtn[i - 1] = '\0';
  }
  return rtn;
}()};

// Indices into the above contiguous array
inline constexpr std::array<char const*, max_number + 1> name_ptr{[]{
  std::array<char const*, max_number + 1> rtn{}; // zero-initialized: null pointers (in case team numbers are missing)
  std::size_t i{0};
  ssize_t eqidx{cx::strchr<'='>(::xxd::gc_team_cfg)};
  std::size_t n{cx::unsigned_atoi(::xxd::gc_team_cfg, 0, eqidx)};
  ssize_t nlidx{cx::strchr<'\n'>(::xxd::gc_team_cfg, static_cast<std::size_t>(eqidx))};
  ssize_t cmidx{cx::strchr<','>(::xxd::gc_team_cfg, static_cast<std::size_t>(eqidx))};
  ssize_t ntidx{(cmidx == -1) ? nlidx : std::min(nlidx, cmidx)};
  rtn[n] = &all_names[i];
  i += static_cast<std::size_t>(ntidx) - eqidx;
  while (-1 != (eqidx = cx::strchr<'='>(::xxd::gc_team_cfg, static_cast<std::size_t>(nlidx) + 1))) {
    n = cx::unsigned_atoi(::xxd::gc_team_cfg, static_cast<std::size_t>(nlidx) + 1, eqidx);
    nlidx = cx::strchr<'\n'>(::xxd::gc_team_cfg, static_cast<std::size_t>(eqidx));
    cmidx = cx::strchr<','>(::xxd::gc_team_cfg, static_cast<std::size_t>(eqidx));
    ntidx = (cmidx == -1) ? nlidx : std::min(nlidx, cmidx);
    rtn[n] = &all_names[i];
    i += static_cast<std::size_t>(ntidx) - eqidx;
  }
  return rtn;
}()};

} // namespace internal

pure static
char const*
name(u8 i) {
  // assert(i >= 1); // "Invisibles" placeholder team := 0
  assert(i <= internal::max_number);
  assert(internal::name_ptr[i] != nullptr);
  return internal::name_ptr[i];
}

inline constexpr u8 upenn{[]{
  for (u8 i{0}; i <= internal::max_number; ++i) {
    if (
      (internal::name_ptr[i] != nullptr) and
      cx::substreq<internal::all_names_len>(internal::all_names, "UPennalizers", static_cast<std::size_t>(internal::name_ptr[i] - internal::all_names.data()))
    ) { return i; }
  }
  assert(false); // NOLINT(misc-static-assert) // ==> we couldn't find "UPennalizers" in the GameController's team config
}()};

} // namespace team
} // namespace gamecontroller
} // namespace config

#endif // CONFIG_TEAMS_HPP
