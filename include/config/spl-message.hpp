#ifndef CONFIG_SPL_MESSAGE_HPP
#define CONFIG_SPL_MESSAGE_HPP

namespace spl {
#define SPLStandardMessage Message // to avoid typing spl::SPL...
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything" // Ignore any errors from SPL code
#include <SPLStandardMessage.h> // check compilation args: -isystem so clang-tidy will stfu

#pragma clang diagnostic pop
#undef SPLStandardMessage

} // namespace spl

#endif // CONFIG_SPL_MESSAGE_HPP
