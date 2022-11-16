#ifndef UTIL_STRINGIFY_HPP
#define UTIL_STRINGIFY_HPP

// NOLINTBEGIN(cppcoreguidelines-macro-usage)
#define STRINGIFY(x) STRINGIFY_(x) // NOLINT(cppcoreguidelines-macro-usage)
#define STRINGIFY_(x) #x
// NOLINTEND(cppcoreguidelines-macro-usage)

#endif // UTIL_STRINGIFY_HPP
