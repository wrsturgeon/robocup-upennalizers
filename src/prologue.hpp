#pragma once

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
inline constexpr unsigned char bits = SYSTEM_BITS;
#undef SYSTEM_BITS
} // namespace system
namespace build {
inline constexpr bool debug = DEBUG;
#undef DEBUG
} // namespace build
namespace logic {
inline constexpr u16 update_freq_ms = 50;
} // namespace logic
} // namespace config

//%%%%%%%%%%%%%%%% Useful macros
#ifdef NDEBUG
#define INLINE_NOATTR inline constexpr
#define INLINE [[gnu::always_inline]] INLINE_NOATTR
#define IMPURE_NOATTR inline
#define impure [[nodiscard]] [[gnu::always_inline]] IMPURE_NOATTR  // not constexpr since std::string for whatever reason isn't
#define CONST_IF_RELEASE const
#define NOX noexcept
#else
#define INLINE_NOATTR constexpr
#define INLINE INLINE_NOATTR
#define IMPURE_NOATTR
#define impure [[nodiscard]] IMPURE_NOATTR
#define NOX
#define CONST_IF_RELEASE
#endif  // NDEBUG
#define PURE_NOATTR INLINE_NOATTR
#define pure [[nodiscard]] PURE_NOATTR
