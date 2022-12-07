#ifndef CONFIG_TEAMS_HPP
#define CONFIG_TEAMS_HPP

// Parse the GameController's source code at compile time
// specifically, ext/GameController/resources/config/spl/teams.cfg

#include <algorithm>            // for std::min, std::copy_n
#include <array>                // for std::array
#include <cstddef>              // for std::size_t, size_t

#include "util/cxstr.hpp"       // for cx::strchr, cx::strchrrev, cx::unsigned_atoi, cx::substreq
#include "xxd/gc_team_cfg.hpp"  // for xxd::gc_team_cfg

extern "C" {
#include <assert.h>             // for assert
#include <sys/types.h>          // for ssize_t, size_t
}

namespace config {
namespace gamecontroller {
namespace team {

#if DEBUG // we won't need to print team names in release mode

namespace internal {

//%%%%%%%%%%%%%%%% Parsing the GameController's source code at compile time

// If you get an error that `__assert_rtn` can't be called in a constant expression, that means the assertion is failing
inline constexpr u8 max_number{[]{
  ssize_t const eqidx{cx::strchrrev<'='>(xxd::gc_team_cfg)};
  assert_neq(-1, eqidx, "no '=' found in the GameController's team config file")
  ssize_t const nlidx{cx::strchrrev<'\n'>(xxd::gc_team_cfg, static_cast<std::size_t>(eqidx) - 1)};
  assert_neq(-1, nlidx, "no newline before the last '=' in the GameController's team config file")
  return cx::unsigned_atoi(xxd::gc_team_cfg, nlidx + 1, eqidx);
}()};

// If you get an error that `__assert_rtn` can't be called in a constant expression, that means the assertion is failing
inline constexpr std::size_t all_names_len{[]{
  ssize_t eqidx{cx::strchr<'='>(xxd::gc_team_cfg)};
  assert_neq(-1, eqidx, "no '=' in the GameController's team config file")
  ssize_t nlidx{cx::strchr<'\n'>(xxd::gc_team_cfg, static_cast<std::size_t>(eqidx) + 1)};
  assert_neq(-1, nlidx, "no newline after the first '=' in the GameController's team config file")
  ssize_t cmidx{cx::strchr<','>(xxd::gc_team_cfg, static_cast<std::size_t>(eqidx) + 1)};
  assert_neq(-1, cmidx, "no comma after the first newline in the GameController's team config file")
  ssize_t ntidx{(cmidx == -1) ? nlidx : std::min(nlidx, cmidx)};
  std::size_t sum{static_cast<std::size_t>(ntidx) - eqidx}; // would be ...-1 but we add a null terminator so they cancel out
  while (-1 != (eqidx = cx::strchr<'='>(xxd::gc_team_cfg, static_cast<std::size_t>(nlidx) + 1))) {
    nlidx = cx::strchr<'\n'>(xxd::gc_team_cfg, static_cast<std::size_t>(eqidx) + 1);
    assert_neq(-1, nlidx, "unmatched '=' (without a newline afterward) in the GameController's team config file")
    cmidx = cx::strchr<','>(xxd::gc_team_cfg, static_cast<std::size_t>(eqidx) + 1);
    // actually fine if we don't have a comma afterward: they seem to be optional
    ntidx = (cmidx == -1) ? nlidx : std::min(nlidx, cmidx);
    sum += static_cast<std::size_t>(ntidx) - eqidx; // would be ...-1 but we add a null terminator so they cancel out
  }
  return sum;
}()};

// Contiguous array separated by null terminators
inline constexpr std::array<char, all_names_len> all_names{[]{
  std::array<char, all_names_len> rtn; // NOLINT(cppcoreguidelines-pro-type-member-init)
  std::size_t i{0};
  ssize_t eqidx{cx::strchr<'='>(xxd::gc_team_cfg)};
  ssize_t nlidx{cx::strchr<'\n'>(xxd::gc_team_cfg, static_cast<std::size_t>(eqidx))};
  ssize_t cmidx{cx::strchr<','>(xxd::gc_team_cfg, static_cast<std::size_t>(eqidx))};
  ssize_t ntidx{(cmidx == -1) ? nlidx : std::min(nlidx, cmidx)};
  std::copy_n(&xxd::gc_team_cfg[eqidx + 1], static_cast<std::size_t>(ntidx) - (eqidx + 1), &rtn[i]);
  i += static_cast<std::size_t>(ntidx) - eqidx;
  rtn[i - 1] = '\0';
  while (-1 != (eqidx = cx::strchr<'='>(xxd::gc_team_cfg, static_cast<std::size_t>(nlidx) + 1))) {
    nlidx = cx::strchr<'\n'>(xxd::gc_team_cfg, static_cast<std::size_t>(eqidx));
    cmidx = cx::strchr<','>(xxd::gc_team_cfg, static_cast<std::size_t>(eqidx));
    ntidx = (cmidx == -1) ? nlidx : std::min(nlidx, cmidx);
    std::copy_n(&xxd::gc_team_cfg[eqidx + 1], static_cast<std::size_t>(ntidx) - (eqidx + 1), &rtn[i]);
    i += static_cast<std::size_t>(ntidx) - eqidx;
    rtn[i - 1] = '\0';
  }
  return rtn;
}()};

// Indices into the above contiguous array
inline constexpr std::array<char const*, max_number + 1> name_ptr{[]{
  std::array<char const*, max_number + 1> rtn{}; // zero-initialized: null pointers (in case team numbers are missing)
  std::size_t i{0};
  ssize_t eqidx{cx::strchr<'='>(xxd::gc_team_cfg)};
  std::size_t n{cx::unsigned_atoi(xxd::gc_team_cfg, 0, eqidx)};
  ssize_t nlidx{cx::strchr<'\n'>(xxd::gc_team_cfg, static_cast<std::size_t>(eqidx))};
  ssize_t cmidx{cx::strchr<','>(xxd::gc_team_cfg, static_cast<std::size_t>(eqidx))};
  ssize_t ntidx{(cmidx == -1) ? nlidx : std::min(nlidx, cmidx)};
  rtn[n] = &all_names[i];
  i += static_cast<std::size_t>(ntidx) - eqidx;
  while (-1 != (eqidx = cx::strchr<'='>(xxd::gc_team_cfg, static_cast<std::size_t>(nlidx) + 1))) {
    n = cx::unsigned_atoi(xxd::gc_team_cfg, static_cast<std::size_t>(nlidx) + 1, eqidx);
    nlidx = cx::strchr<'\n'>(xxd::gc_team_cfg, static_cast<std::size_t>(eqidx));
    cmidx = cx::strchr<','>(xxd::gc_team_cfg, static_cast<std::size_t>(eqidx));
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

#endif // DEBUG

inline constexpr u8 upenn{[]{
#if DEBUG
  for (u8 i{0}; i <= internal::max_number; ++i) {
    if ((internal::name_ptr[i] != nullptr)
    and cx::substreq<true>(internal::all_names, "UPennalizers", static_cast<std::size_t>(internal::name_ptr[i] - internal::all_names.data()))
    ) { return i; }
  }
  assert_neq(0, 0, "couldn't find \"UPennalizers\" in the GameController's team config file")
#else
  ssize_t eqidx{0};
  while (-1 != (eqidx = cx::strchr<'='>(xxd::gc_team_cfg, static_cast<std::size_t>(eqidx) + 1))) {
    if (cx::substreq<false>(xxd::gc_team_cfg, "UPennalizers,", static_cast<std::size_t>(eqidx) + 1)) {
      return cx::unsigned_atoi(xxd::gc_team_cfg, cx::strchrrev<'\n'>(xxd::gc_team_cfg, static_cast<std::size_t>(eqidx) - 1) + 1, eqidx);
    }
  }
  assert_neq(0, 0, "couldn't find \"UPennalizers\" in the GameController's team config file")
#endif
}()};

} // namespace team
} // namespace gamecontroller
} // namespace config

#endif // CONFIG_TEAMS_HPP
