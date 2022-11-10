#pragma once

#include "config/wireless.hpp"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything" // Ignore any errors from asio
#include "asio/ip/udp.hpp"
#include "asio/signal_set.hpp"
#pragma clang diagnostic pop

#include <cstddef> // std::size_t
#include <iostream> // std::cerr, std::cout

namespace msg {
namespace udp {

// https://think-async.com/Asio/asio-1.22.1/doc/asio/reference/WriteToken.html
static void asio_write_verbose(asio::error_code const& ec, std::size_t bytes_transferred) {
  if (ec) { std::cerr << "ASIO error: " << ec.message() << '\n'; }
  else { std::cout << "ASIO: transferred " << bytes_transferred << " bytes\n"; }
}
static void asio_write_quiet(asio::error_code const& ec, std::size_t /*bytes_transferred*/) {
  if (ec) { std::cerr << "ASIO: ERROR: " << ec.message() << '\n'; }
}

static void open_communication(asio::io_context& ctx) noexcept {

  /*
  // UDP test--WORKS!
  // Sends made-up bullshit to the TeamCommunicationMonitor (utility in GameController/bin)
  auto s = asio::ip::udp::socket{ctx};
  auto gc = asio::ip::udp::endpoint{asio::ip::make_address_v4(config::gamecontroller::ip), config::udp::team_port};
  s.open(asio::ip::udp::v4());
  s.async_send_to(asio::buffer("Hello, world!", 13), gc, asio_write_verbose);
  s.close();
  */

  auto s = asio::ip::udp::socket{ctx};
  auto me = asio::ip::udp::endpoint{asio::ip::make_address_v4(config::player::ip), 2};
  auto gc = asio::ip::udp::endpoint{asio::ip::make_address_v4(config::gamecontroller::ip), /*config::udp::gamecontroller::recv::port*/ config::udp::team_port};
  s.open(asio::ip::udp::v4());
  // s.bind(me);
  s.async_send_to(asio::buffer("Hello, world!", 13), gc, asio_write_verbose);
  s.close();
}

} // namespace udp
} // namespace msg
