#ifndef PROLOGUE_HPP
#define PROLOGUE_HPP

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

#include <cerrno>   // errno
#include <cstring>  // strerror_r
#include <iostream> // std::cerr

template <std::size_t N>
static
void
get_system_error_message(char (&buf)[N]) noexcept
{
  int const orig = errno;
  int const rtn = strerror_r(orig, static_cast<char*>(buf), N);
  if (rtn) {
    try {
      std::cerr << "strerror_r failed (returned " << rtn << ", errno = " << errno
                << ") while handling original errno " << orig << std::endl;
    } catch (...) {/* std::terminate below */}
    std::terminate();
  }
}

#if DEBUG
#define FAIL_ASSERTION                           \
  char buf[256];                                 \
  get_system_error_message(buf);                 \
  try {                                          \
    std::cerr << errmsg                          \
              << " (errno" << errno              \
              << ": " << static_cast<char*>(buf) \
              << ")\n";                          \
  } catch (...) {/* std::terminate below */}     \
  std::terminate();
#else // DEBUG
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-parameter"
#endif // DEBUG

template <typename T>
INLINE
void
assert_zero(T&& expr, char const* const errmsg) noexcept
{
#if DEBUG
  if (expr) { FAIL_ASSERTION }
#endif // DEBUG
}

template <typename T>
INLINE
void
assert_nonzero(T&& expr, char const* const errmsg) noexcept
{
#if DEBUG
  if (!expr) { FAIL_ASSERTION }
#endif // DEBUG
}

#if !DEBUG
#pragma clang diagnostic pop
#endif // !DEBUG
#undef FAIL_ASSERTION

//%%%%%%%%%%%%%%%% Stack-allocation without initialization

template <typename T>
pure std::decay_t<T>
uninitialized()
{
  char bytes[sizeof(std::decay_t<T>)];
  return *reinterpret_cast<std::decay_t<T>*>(bytes);
}

#endif // PROLOGUE_HPP
