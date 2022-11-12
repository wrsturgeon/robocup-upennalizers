#pragma once

#include "src/msg/asio.hpp"

#include <iostream>  // std::cout
#include <stdexcept> // std::runtime_error

namespace msg {

class SignalHandler {
  boost::asio::io_context& ioctx;
 public:
  INLINE SignalHandler(boost::asio::io_context& io_context) noexcept : ioctx{io_context} {}
  INLINE void operator()(boost::system::error_code const& ec, int signal_number);
};

INLINE void SignalHandler::operator()(boost::system::error_code const& ec, int signal_number) {
  if (ec) {
    throw std::runtime_error{"ASIO: ERROR: " + ec.message()};
  } else {
    std::cout << "ASIO: SIGNAL: " << signal_number << " received\n";
    ioctx.stop();
  }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-function" // Who cares which you end up using

static void write_handler_verbose(boost::system::error_code const& ec, std::size_t bytes_transferred) {
  if (ec) { throw std::runtime_error{"ASIO: ERROR: " + ec.message()}; }
  else { std::cout << "ASIO: transferred " << bytes_transferred << " bytes\n"; }
}

static void write_handler_quiet(boost::system::error_code const& ec, std::size_t /*bytes_transferred*/) {
  if (ec) { throw std::runtime_error{"ASIO: ERROR: " + ec.message()}; }
  // nothing otherwise
}

#pragma clang diagnostic pop

} // namespace msg
