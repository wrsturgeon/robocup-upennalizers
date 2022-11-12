#pragma once

#include "src/ctx/loop-fwd.hpp"

#include "src/ctx/context-fwd.hpp"

#include <iostream> // std::cerr

namespace ctx {

template <config::gamecontroller::competition::phase::t CompetitionPhase,
          config::gamecontroller::competition::type ::t CompetitionType>
Loop<CompetitionPhase, CompetitionType>::Loop(Context<CompetitionPhase, CompetitionType>& context_ref) noexcept
    : context{context_ref},
      ioctx{},
      socket{ioctx/*, gc_endpoint*/},
      timer{ioctx, update_period}
{

  // Stop if we're asked to
  boost::asio::signal_set{ioctx, SIGINT, SIGTERM}.async_wait(msg::SignalHandler{ioctx});

  // Open the connection
  socket.open(boost::asio::ip::udp::v4());

  // Start the loop
  timer.async_wait([this](boost::system::error_code const& ec) noexcept { (*this)(ec); });

  // Go!
  ioctx.run();
}

template <config::gamecontroller::competition::phase::t CompetitionPhase,
          config::gamecontroller::competition::type ::t CompetitionType>
void
Loop<CompetitionPhase, CompetitionType>::operator()(boost::system::error_code const& ec) noexcept
{
  if (ec) { std::cerr << "ASIO error: " << ec.message() << '\n'; return; }
  std::cout << "Looping\n";
  auto msg = static_cast<spl::Message>(context);
  auto const bytes = socket.send_to(boost::asio::buffer(&msg, sizeof msg), gc_endpoint);
  assert(bytes == sizeof msg);
  timer.expires_at(timer.expires_at() + update_period);
  timer.async_wait([this](boost::system::error_code const& ec_2) noexcept { (*this)(ec_2); });
}

} // namespace ctx
