#pragma once

#include <cstddef>  // std::size_t
#include <iostream> // std::cerr
#include <fstream>  // std::ifstream
#include <string>   // std::string

namespace util {

template <std::size_t N>
static auto
read_file(char const (&path)[N])
-> std::string {
  auto s = std::string{};
  auto f = std::ifstream{path};
  if (!f) {
    std::cerr << "Couldn't open " << path << std::endl;
    return s;
  }
  f.seekg(0, std::ios::end);
  auto pos = f.tellg();
  if (pos < 0) {
    std::cerr << "Couldn't seek to the end of " << path << std::endl;
    return s;
  }
  if (pos == 0) {
    std::cerr << "File " << path << " is empty" << std::endl;
    return s;
  }
  s.resize(static_cast<std::size_t>(pos));
  f.seekg(0, std::ios::beg);
  f.read(&s[0], pos);
  if (!f) {
    std::cerr << "Couldn't read " << path << std::endl;
    return s;
  }
  std::cout << "Contents of " << path << ": \"" << s << "\"\n";
  return s;
}

} // namespace util
