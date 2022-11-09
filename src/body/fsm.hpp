#pragma once

namespace body {
  
struct FSM {
  INLINE FSM() noexcept {}
  pure auto update() noexcept -> bool;
};

pure auto
FSM::update() noexcept
-> bool {
  return false; // for now; will exist in various branches
  return true; // continue
}

} // namespace body
