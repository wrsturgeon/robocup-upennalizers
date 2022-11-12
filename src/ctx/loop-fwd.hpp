#pragma once

#include "src/ctx/context-fwd-fwd.hpp"
#include "src/msg/udp.hpp"

#include "config/gamecontroller.hpp"

namespace ctx {

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpadded"
template <config::gamecontroller::competition::phase::t CompetitionPhase,
          config::gamecontroller::competition::type ::t CompetitionType>
class Loop {
  static constexpr boost::posix_time::milliseconds update_period{config::logic::update_period_ms};
  Context<CompetitionPhase, CompetitionType>& context;
  boost::asio::io_context ioctx;
  boost::asio::ip::udp::socket socket;
  boost::asio::deadline_timer timer;
  boost::asio::ip::udp::endpoint const gc_endpoint{boost::asio::ip::make_address(config::gamecontroller::ip), /* config::udp::gamecontroller::send::port */ config::udp::team_port};
 public:
  Loop(Context<CompetitionPhase, CompetitionType>& context_ref) noexcept;
  Loop(Loop const&) = delete;
  Loop(Loop&&) = delete;
  Loop& operator=(Loop const&) = delete;
  Loop& operator=(Loop&&) = delete;
  void operator()(boost::system::error_code const& ec) noexcept;
};
#pragma clang diagnostic pop

} // namespace ctx
