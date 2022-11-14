#pragma once

// pull from ext/GameController/resources/config/spl/teams.cfg

#include <array>    // std::array
#include <cassert>  // assert
#include <fstream>  // std::ifstream
#include <iostream> // std::cerr
#include <string>   // std::string

namespace config {
namespace gamecontroller {
namespace team {

namespace internal {
inline std::array<std::string, 256> number;
} // namespace internal

// clever trick: run code outside main by returning into a variable (that we'll use often!)
inline u8 const count = []() -> u8 {
  std::ifstream file{"../ext/GameController/resources/config/spl/teams.cfg"};
  if (!file) {
    std::cerr << "Couldn't open ../ext/GameController/resources/config/spl/teams.cfg" << std::endl;
    std::exit(1);
  }
  std::string line; // Format: ^[team number]=[team name]$ or ^[team number]=[team name],[team colors...]
  i16 most_so_far = -1;
  u16 line_n = 0;
  while (std::getline(file, line)) {
    ++line_n;
    if (line.empty()) { return static_cast<u8>(most_so_far); }
    const auto eq_idx = line.find('=');
    if (eq_idx == std::string::npos) {
      std::cerr << "Invalid line " << +line_n << " in ../ext/GameController/resources/config/spl/teams.cfg (no '=' found)\n";
      std::exit(1);
    }
    const auto team_number = std::stoi(line.substr(0, eq_idx));
    if (team_number <= most_so_far) {
      std::cerr << "Invalid line " << +line_n << " in ../ext/GameController/resources/config/spl/teams.cfg (team number " << +team_number << " not strictly monotonically increasing)\n";
      std::exit(1);
    }
    if (team_number > 255) {
      std::cerr << "Invalid line " << +line_n << " in ../ext/GameController/resources/config/spl/teams.cfg (team number " << +team_number << " > 255)\n";
      std::exit(1);
    }
    most_so_far = static_cast<u8>(team_number);
    const auto comma_idx = line.find(',');
    if (comma_idx == std::string::npos) {
      internal::number[static_cast<u8>(most_so_far)] = line.substr(eq_idx + 1);
    } else {
      internal::number[static_cast<u8>(most_so_far)] = line.substr(eq_idx + 1, comma_idx - eq_idx - 1);
    }
  }
  return static_cast<u8>(most_so_far);
}();

inline u8 const upenn = []{
  for (u8 i = 1; i <= count; ++i) { if (internal::number[i] == "UPennalizers") { return i; } }
  std::cerr << "Couldn't find UPennalizers in ../ext/GameController/resources/config/spl/teams.cfg" << std::endl;
  std::exit(1);
}();

impure static auto
number(u8 i) noexcept
-> std::string const& {
  // assert(i >= 1); // "Invisibles" placeholder team := 0
  assert(i <= count);
  return internal::number[i];
}

} // namespace team
} // namespace gamecontroller
} // namespace config
