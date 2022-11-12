#pragma once

#include "src/ctx/context-fwd-fwd.hpp"
#include "src/msg/asio.hpp"

#include "config/gamecontroller.hpp"
#include "config/wireless.hpp"

#include <thread> // std::thread

namespace ctx {

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpadded"
template <config::gamecontroller::competition::phase::t CompetitionPhase,
          config::gamecontroller::competition::type ::t CompetitionType>
class Loop {
  static constexpr boost::posix_time::milliseconds update_period{config::logic::update_period_ms};
  boost::asio::ip::udp::endpoint const gc_endpoint{boost::asio::ip::make_address(config::gamecontroller::ip), /* config::udp::gamecontroller::send::port */ config::udp::team_port};
  Context<CompetitionPhase, CompetitionType>& context;
  boost::asio::io_context ioctx;
  boost::asio::signal_set signals;
  boost::asio::ip::udp::socket socket;
  boost::asio::deadline_timer timer;
  std::thread thread;
#if DEBUG
  static std::atomic<bool> any_loop_started;
#endif
 public:
  Loop(Context<CompetitionPhase, CompetitionType>& context_ref) noexcept;
  Loop(Loop const&) = delete;
  Loop(Loop&&) = delete;
  auto operator=(Loop const&) -> Loop& = delete;
  auto operator=(Loop&&) -> Loop& = delete;
  ~Loop() noexcept { ioctx.stop(); thread.join(); }
  void operator()(boost::system::error_code const& ec);
};
#pragma clang diagnostic pop

} // namespace ctx
