#ifndef CONFIG_TEAMS_HPP
#define CONFIG_TEAMS_HPP

// pull from ext/GameController/resources/config/spl/teams.cfg

#include "file/contents.hpp"

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
    std::ifstream file{"include/ext/GameController/resources/config/spl/teams.cfg"};
    if (!file) { throw file::error{"Couldn't open include/ext/GameController/resources/config/spl/teams.cfg"}; }
    std::string line; // Format: ^[team number]=[team name]$ or ^[team number]=[team name],[team colors...]
    i16 most_so_far{-1};
    std::vector<std::string> names;
    u16 line_n{0};
    while (std::getline(file, line)) {
      ++line_n;
      if (line.empty()) { continue; }
      std::size_t const eq_idx{line.find('=')};
      if (eq_idx == std::string::npos) { throw std::logic_error{"Invalid line " + std::to_string(line_n) + " in include/ext/GameController/resources/config/spl/teams.cfg (no '=' found)"}; }
      int const team_number{std::stoi(line.substr(0, eq_idx))};
#if DEBUG || VERBOSE
      if (team_number != most_so_far + 1) { std::cerr << "Suspicious line " << +line_n << " in include/ext/GameController/resources/config/spl/teams.cfg: jumping to team number " << +team_number << " skips at least one\n"; }
#endif // DEBUG || VERBOSE
      if (team_number <= most_so_far) { throw std::logic_error{"Invalid line " + std::to_string(line_n) + " in include/ext/GameController/resources/config/spl/teams.cfg (team number " + std::to_string(team_number) + " not strictly monotonically increasing)"}; }
      if (team_number > 255) { throw std::logic_error{"Invalid line " + std::to_string(line_n) + " in include/ext/GameController/resources/config/spl/teams.cfg (team number " + std::to_string(team_number) + " > 255)"}; }
      most_so_far = static_cast<i16>(team_number);
      std::size_t const comma_idx{line.find(',')};
      std::cout << "Pushing back...\n";
      names.push_back((comma_idx == std::string::npos) ? line.substr(eq_idx + 1) : line.substr(eq_idx + 1, comma_idx - eq_idx - 1));
      std::cout << "names.size() = " << names.size() << std::endl;
    }
    return names; }()};
  // assert(i >= 1); // "Invisibles" placeholder team := 0
#if DEBUG
  if (i >= name_vec.size()) { throw std::out_of_range{"Team number " + std::to_string(i) + " requested, but only " + std::to_string(name_vec.size()) + " teams defined"}; }
#endif // DEBUG
  return name_vec[i];
}

impure static
u8
upenn_number()
{
  static u8 const idx{[] {
    try { u8 i = 0; do { if (name(i) == "UPennalizers") { return i; } } while (++i); } catch (std::out_of_range const&) {/* below */}
    throw std::logic_error{"Couldn't find UPennalizers in include/ext/GameController/resources/config/spl/teams.cfg"}; }()};
  return idx;
}

} // namespace team
} // namespace gamecontroller
} // namespace config

#endif // CONFIG_TEAMS_HPP
