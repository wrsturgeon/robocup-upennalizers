#pragma once

#include "src/msg/asio.hpp"

#include <iostream> // std::cerr

namespace msg {

class SignalHandler {
  boost::asio::io_context& ioctx;
 public:
  INLINE SignalHandler(boost::asio::io_context& io_context) noexcept : ioctx{io_context} {}
  INLINE void operator()(boost::system::error_code const& ec, int signal_number) noexcept;
};

INLINE void SignalHandler::operator()(boost::system::error_code const& ec, int signal_number) noexcept {
  if (ec) {
    std::cerr << "ASIO: ERROR: " << ec.message() << '\n';
  } else {
    std::cout << "ASIO: signal " << signal_number << " received\n";
    ioctx.stop();
  }
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-function" // Who cares which you end up using

static void write_handler_verbose(boost::system::error_code const& ec, std::size_t bytes_transferred) {
  if (ec) { std::cerr << "ASIO error: " << ec.message() << '\n'; }
  else { std::cout << "ASIO: transferred " << bytes_transferred << " bytes\n"; }
}

static void write_handler_quiet(boost::system::error_code const& ec, std::size_t /*bytes_transferred*/) {
  if (ec) { std::cerr << "ASIO: ERROR: " << ec.message() << '\n'; }
  // nothing otherwise
}

#pragma clang diagnostic pop

} // namespace msg
