#pragma once

#include "src/ctx/loop-fwd.hpp"

#include "src/ctx/context-fwd.hpp"
#include "src/msg/handlers.hpp"

#include <stdexcept> // std::runtime_error

#if DEBUG
#include <iostream> // std::cout
#endif

namespace ctx {

#if DEBUG
template <config::gamecontroller::competition::phase::t CompetitionPhase,
          config::gamecontroller::competition::type ::t CompetitionType>
std::atomic<bool> Loop<CompetitionPhase, CompetitionType>::any_loop_started = false;
#endif

template <config::gamecontroller::competition::phase::t CompetitionPhase,
          config::gamecontroller::competition::type ::t CompetitionType>
Loop<CompetitionPhase, CompetitionType>::Loop(Context<CompetitionPhase, CompetitionType>& context_ref) noexcept
    : context{context_ref},
      ioctx{},
      signals{ioctx, SIGINT, SIGTERM},
      socket{ioctx/*, gc_endpoint*/},
      timer{ioctx, update_period},
      thread{[this]() {
        signals.async_wait(msg::SignalHandler{ioctx});
        socket.open(boost::asio::ip::udp::v4());
        timer.async_wait([this](boost::system::error_code const& ec) { (*this)(ec); });
        ioctx.run();
      }}
{
#if DEBUG
  assert(!any_loop_started.exchange(true)); // exactly one loop per game
#endif
}

template <config::gamecontroller::competition::phase::t CompetitionPhase,
          config::gamecontroller::competition::type ::t CompetitionType>
void
Loop<CompetitionPhase, CompetitionType>::operator()(boost::system::error_code const& ec)
{
  if (ec) { throw std::runtime_error{"ASIO error: " + ec.message()}; }
  auto msg = static_cast<spl::Message>(context);
  auto const bytes = socket.send_to(boost::asio::buffer(&msg, sizeof msg), gc_endpoint);
#if DEBUG
  assert(bytes == sizeof msg);
  std::cout << "Sent " << bytes << " bytes to " << gc_endpoint << std::endl;
#endif
  timer.expires_at(timer.expires_at() + update_period);
  timer.async_wait([this](boost::system::error_code const& ec_2) noexcept { (*this)(ec_2); });
}

} // namespace ctx
