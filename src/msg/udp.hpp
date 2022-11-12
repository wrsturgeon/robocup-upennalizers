#pragma once

#include "src/msg/handlers.hpp"

#include "src/msg/asio.hpp"

#include "config/wireless.hpp"

namespace msg {
namespace udp {

// static void open_communication(boost::asio::io_context& ctx) noexcept {

//   /*
//   // UDP test--WORKS!
//   // Sends made-up bullshit to the TeamCommunicationMonitor (utility in GameController/bin)
//   auto s = boost::asio::ip::udp::socket{ctx};
//   auto gc = boost::asio::ip::udp::endpoint{boost::asio::ip::make_address_v4(config::gamecontroller::ip), config::udp::team_port};
//   s.open(boost::asio::ip::udp::v4());
//   s.async_send_to(boost::asio::buffer("Hello, world!", 13), gc, asio_write_verbose);
//   s.close();
//   */

//   auto s = boost::asio::ip::udp::socket{ctx};
//   auto gc = boost::asio::ip::udp::endpoint{boost::asio::ip::make_address_v4(config::gamecontroller::ip), /*config::udp::gamecontroller::recv::port*/ config::udp::team_port};
//   s.open(boost::asio::ip::udp::v4());
//   auto const msg = spl::Message{};
//   s.async_send_to(boost::asio::buffer(&msg, sizeof msg), gc, ::msg::write_handler_quiet);
//   s.close();
// }

} // namespace udp
} // namespace msg
