#include "config/teams.hpp"

#include <iostream>

int main() {
  std::cout << +config::gamecontroller::team::internal::max_number << std::endl;
  for (char const& c : config::gamecontroller::team::internal::all_names) {
    if (c) std::cout << c; else std::cout << "\\0";
  }
  std::cout << std::endl << std::endl;
  for (auto const& ptr : config::gamecontroller::team::internal::name_ptr) {
    std::cout << ((ptr != nullptr) ? ptr : "[none]") << std::endl;
  }
}
