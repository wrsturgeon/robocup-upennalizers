#ifndef MESSAGING_ERROR_HPP
#define MESSAGING_ERROR_HPP

namespace msg {

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wweak-vtables"
class error : public std::runtime_error { using std::runtime_error::runtime_error; };
#pragma clang diagnostic pop

} // namespace msg

#endif // MESSAGING_ERROR_HPP
