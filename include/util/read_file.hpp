#ifndef UTIL_READ_FILE_HPP
#define UTIL_READ_FILE_HPP

#include <cstddef>  // std::size_t
#include <fstream>  // std::ifstream
#include <iostream> // std::cerr
#include <string>   // std::string

namespace util {

static
std::string
read_file(char const* const path)
{
  std::string s{};
  std::ifstream f{path};
  if (!f) { throw std::runtime_error{"Couldn't open " + std::string{path}}; }
  f.seekg(0, std::ios::end);
  std::streampos const pos{f.tellg()};
  if (pos < 0) { throw std::runtime_error{"Couldn't seek to end of " + std::string{path}}; }
  if (pos == 0) { throw std::runtime_error{"File " + std::string{path} + " is empty"}; }
  s.resize(static_cast<std::size_t>(pos));
  f.seekg(0, std::ios::beg);
  f.read(&s[0], pos);
  if (!f) { throw std::runtime_error{"Couldn't read " + std::string{path}}; }
#ifdef VERBOSE
  std::cout << "Contents of " << path << ": \"" << s << "\"\n";
#endif
  return s;
}

} // namespace util

#endif // UTIL_READ_FILE_HPP
