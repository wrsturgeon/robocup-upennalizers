#ifndef CONCURRENCY_ERROR_HPP
#define CONCURRENCY_ERROR_HPP

#ifdef NDEBUG && !defined(VSCODE_PARSE)
#warning "Can't be throwing concurrency exceptions in release mode :/"
#else // NDEBUG

#include <stdexcept> // std::runtime_error

namespace concurrency {

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wweak-vtables"
class error : public std::runtime_error { using std::runtime_error::runtime_error; };
#pragma clang diagnostic pop

} // namespace concurrency

#endif // NDEBUG

#endif // CONCURRENCY_ERROR_HPP
