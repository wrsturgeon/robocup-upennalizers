#ifndef FILE_CONTENTS_HPP
#define FILE_CONTENTS_HPP

#include "util/fixed-string.hpp"

#include <cstddef>  // std::size_t
#include <fstream>  // std::ifstream
#include <iostream> // std::cerr
#include <string>   // std::string

namespace file {

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wweak-vtables"
class error : public std::runtime_error { using std::runtime_error::runtime_error; };
#pragma clang diagnostic pop

// File is read once and cached in memory to be returned each subsequent time.
template <util::FixedString path>
static
char const*
contents()
{
  static std::string const str{[]{
    std::string s{};
    std::ifstream f{path.c_str()};
    if (!f) { throw error{"Couldn't open " + path}; }
    f.seekg(0, std::ios::end);
    std::streampos const pos{f.tellg()};
    if (pos < 0) { throw error{"Couldn't seek to end of " + path}; }
    if (pos == 0) { throw error{"File " + path + " is empty"}; }
    s.resize(static_cast<std::size_t>(pos));
    f.seekg(0, std::ios::beg);
    f.read(&s[0], pos);
    if (!f) { throw error{"Couldn't read " + path}; }
#ifdef VERBOSE
    std::cout << "Contents of " << path.c_str() << ": \"" << s << "\"\n";
#endif
    return s;
  }()};
  return str.c_str();
}

} // namespace file

#endif // FILE_CONTENTS_HPP
