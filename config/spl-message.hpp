#pragma once

namespace spl {
#define SPLStandardMessage Message // to avoid typing spl::SPL...
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything" // Ignore any errors from SPL code
#include "ext/GameController/examples/c/SPLStandardMessage.h"
#pragma clang diagnostic pop
#undef SPLStandardMessage
} // namespace spl
