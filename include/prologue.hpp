#ifndef PROLOGUE_HPP
#define PROLOGUE_HPP

#define _GNU_SOURCE // https://man7.org/linux/man-pages/man7/feature_test_macros.7.html

//%%%%%%%%%%%%%%%% Lua
// extern "C" {
// #include "ext/lua/lauxlib.h"
// #include "ext/lua/lua.h"
// #include "ext/lua/lualib.h"
// }

//%%%%%%%%%%%%%%%% Standard integral types
#ifndef SYSTEM_BITS
#error "SYSTEM_BITS is not defined; pass -DSYSTEM_BITS=$(getconf LONG_BIT) to the compiler"
#endif
#include <cstddef>
#include <cstdint>
#include <type_traits>
template <unsigned char B> struct  intb_s {};
template <unsigned char B> struct uintb_s {};
#if SYSTEM_BITS >=  8
using  i8 = std::int8_t;
using  u8 = std::uint8_t;
template <> struct  intb_s< 8> { using type =  i8; };
template <> struct uintb_s< 8> { using type =  u8; };
#if SYSTEM_BITS >= 16
using i16 = std::int16_t;
using u16 = std::uint16_t;
template <> struct  intb_s<16> { using type = i16; };
template <> struct uintb_s<16> { using type = u16; };
#if SYSTEM_BITS >= 32
using i32 = std::int32_t;
using u32 = std::uint32_t;
template <> struct  intb_s<32> { using type = i32; };
template <> struct uintb_s<32> { using type = u32; };
#if SYSTEM_BITS >= 64
using i64 = std::int64_t;
using u64 = std::uint64_t;
template <> struct  intb_s<64> { using type = i64; };
template <> struct uintb_s<64> { using type = u64; };
#endif // 64
#endif // 32
#endif // 16
#endif //  8
template <unsigned char B> using  intb = typename  intb_s<B>::type;
template <unsigned char B> using uintb = typename uintb_s<B>::type;
using ifull_t =  intb<SYSTEM_BITS>;
using ufull_t = uintb<SYSTEM_BITS>;

//%%%%%%%%%%%%%%%% Configuration
namespace config {

namespace system {
inline constexpr u8 bits{SYSTEM_BITS};
#undef SYSTEM_BITS
} // namespace system

namespace build {
inline constexpr bool debug{DEBUG};
#if DEBUG
#ifdef NDEBUG
#error "DEBUG=1 but NDEBUG is defined (assertions are bypassed)"
#endif // NDEBUG
#else // DEBUG
#ifndef NDEBUG
#warning "DEBUG=0 but NDEBUG is not defined (assertions are checked at runtime)"
#else // NDEBUG
#if NDEBUG != 1
#error "NDEBUG is defined, but not to 1"
#endif // NDEBUG != 1
#endif // NDEBUG
#endif // DEBUG
} // namespace build

} // namespace config

//%%%%%%%%%%%%%%%% Useful macros
#define INLINE [[gnu::always_inline]] inline constexpr
#define pure [[nodiscard]] INLINE
#define impure [[nodiscard]] [[gnu::always_inline]] inline // not constexpr since std::string for whatever reason isn't

// NOLINTBEGIN(cppcoreguidelines-macro-usage)
#define STRINGIFY(x) STRINGIFY_(x) // NOLINT(cppcoreguidelines-macro-usage)
#define STRINGIFY_(x) #x
// NOLINTEND(cppcoreguidelines-macro-usage)

#if DEBUG
#include <cerrno>   // errno
#include <cstring>  // strerror_r
#include <iostream> // std::cerr

template <typename... T>
INLINE static
void
safe_print(std::ostream& stream, T&&... args)
noexcept {
  try {
    (stream << ... << args) << std::endl; // NOLINT(cppcoreguidelines-pro-bounds-array-to-pointer-decay)
  } catch (std::exception const& e) {
    try {
      std::cerr << "safe_print failed: " << e.what() << std::endl;
    } catch (...) { try { std::cerr << "safe_print failed and printing the exception failed\n"; } catch (...) {} }
    std::terminate();
  } catch (...) {
    try { std::cerr << "safe_print failed with an exception not derived from std::exception\n"; } catch (...) {}
    std::terminate();
  }
}

template <std::size_t N>
static
void
get_system_error_message(char (&buf)[N])
noexcept {
  int const orig = errno;
  int const rtn = strerror_r(orig, static_cast<char*>(buf), N);
  if (rtn) {
    safe_print(std::cerr, "strerror_r failed (returned ", rtn, ", errno = ", errno, ") while handling original errno ", orig);
    std::terminate();
  }
}

// NOLINTNEXTLINE(cppcoreguidelines-macro-usage)
#define FAIL_ASSERTION(...)                                                                  \
  char buf[256];                                                                             \
  get_system_error_message(buf);                                                             \
  safe_print(std::cerr, __VA_ARGS__, " (errno ", errno, ": ", static_cast<char*>(buf), ')'); \
  std::terminate();

#else // DEBUG
#define FAIL_ASSERTION(...) std::terminate();
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-parameter"
#endif // DEBUG

// NOLINTBEGIN(cppcoreguidelines-macro-usage)
#define assert_eq(a, b, ...) if ((a) != (b)) { FAIL_ASSERTION(__VA_ARGS__) }
#define assert_neq(a, b, ...) if ((a) == (b)) { FAIL_ASSERTION(__VA_ARGS__) }
#define assert_nonneg(a, ...) if ((a) < 0) { FAIL_ASSERTION(__VA_ARGS__) }
// NOLINTEND(cppcoreguidelines-macro-usage)

#if DEBUG
#define debug_print(...) safe_print(__VA_ARGS__) // NOLINT(cppcoreguidelines-macro-usage)
#else // DEBUG
#define debug_print(...) (void)0 // NOLINT(cppcoreguidelines-macro-usage)
#pragma clang diagnostic pop
#endif // !DEBUG

//%%%%%%%%%%%%%%%% Stack-allocation without initialization

template <typename T>
pure std::decay_t<T>
uninitialized()
noexcept {
  char bytes[sizeof(std::decay_t<T>)];
  return *reinterpret_cast<std::decay_t<T>*>(bytes);
}

#endif // PROLOGUE_HPP
