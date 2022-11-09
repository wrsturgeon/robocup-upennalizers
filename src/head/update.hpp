#pragma once

namespace head {

pure static auto
update(FSM const& /*fsm*/) noexcept
-> bool {
  return false; // for now; will exist in various branches
  return true; // continue
}

} // namespace head
