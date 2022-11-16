#ifndef CONFIG_TEAMS_HPP
#define CONFIG_TEAMS_HPP

// pull from ext/GameController/resources/config/spl/teams.cfg

#include <cassert>  // assert
#include <fstream>  // std::ifstream
#include <iostream> // std::cerr
#include <string>   // std::string
#include <utility>  // std::pair
#include <vector>   // std::vector

namespace config {
namespace gamecontroller {
namespace team {

impure static
std::string const&
name(u8 i)
{
  static std::vector<std::string> const name_vec{[] {
    std::ifstream file{PWDINCLUDE "ext/GameController/resources/config/spl/teams.cfg"};
    if (!file) { throw std::runtime_error{"Couldn't open " PWDINCLUDE "ext/GameController/resources/config/spl/teams.cfg"}; }
    std::string line; // Format: ^[team number]=[team name]$ or ^[team number]=[team name],[team colors...]
    i16 most_so_far{-1};
    std::vector<std::string> names;
    u16 line_n{0};
    while (std::getline(file, line)) {
      ++line_n;
      if (line.empty()) { continue; }
      std::size_t const eq_idx{line.find('=')};
      if (eq_idx == std::string::npos) { throw std::logic_error{"Invalid line " + std::to_string(line_n) + " in " PWDINCLUDE "ext/GameController/resources/config/spl/teams.cfg (no '=' found)"}; }
      int const team_number{std::stoi(line.substr(0, eq_idx))};
      if (team_number != most_so_far + 1) { throw std::logic_error{"Invalid line " + std::to_string(line_n) + " in " PWDINCLUDE "ext/GameController/resources/config/spl/teams.cfg (team number " + std::to_string(team_number) + " not monotonically increasing by 1)"}; }
      if (team_number > 255) { throw std::logic_error{"Invalid line " + std::to_string(line_n) + " in " PWDINCLUDE "ext/GameController/resources/config/spl/teams.cfg (team number " + std::to_string(team_number) + " > 255)"}; }
      ++most_so_far;
      std::size_t const comma_idx{line.find(',')};
      names.push_back((comma_idx == std::string::npos) ? line.substr(eq_idx + 1) : line.substr(eq_idx + 1, comma_idx - eq_idx - 1));
    }
    return names; }()};
  // assert(i >= 1); // "Invisibles" placeholder team := 0
  assert(i < name_vec.size());
  return name_vec[i];
}

impure static
u8
upenn_number()
{
  static u8 const idx{[] {
    for (u8 i{0}; i < 255; ++i) { if (name(i) == "UPenn") { return i; } }
    throw std::logic_error{"Couldn't find UPennalizers in " PWDINCLUDE "ext/GameController/resources/config/spl/teams.cfg"}; }()};
  return idx;
}

} // namespace team
} // namespace gamecontroller
} // namespace config

#endif // CONFIG_TEAMS_HPP
