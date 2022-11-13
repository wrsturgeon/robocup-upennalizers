#pragma once

#include <algorithm>

#if DEBUG
#include <bitset>
#include <iostream>
#endif

namespace spl {
#define RoboCupGameControlData GameControlData
#define RoboCupGameControlReturnData GameControlReturnData
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything" // Ignore any errors from SPL code
#include "ext/GameController/examples/c/RoboCupGameControlData.h"
#pragma clang diagnostic pop
#undef RoboCupGameControlReturnData
#undef RoboCupGameControlData
} // namespace spl

namespace config {
namespace gamecontroller {

inline constexpr u8 max_players = MAX_NUM_PLAYERS;
#undef MAX_NUM_PLAYERS

namespace team {
using t = u8;
inline constexpr t blue = TEAM_BLUE;
#undef TEAM_BLUE
inline constexpr t red = TEAM_RED;
#undef TEAM_RED
inline constexpr t yellow = TEAM_YELLOW;
#undef TEAM_YELLOW
inline constexpr t black = TEAM_BLACK;
#undef TEAM_BLACK
inline constexpr t white = TEAM_WHITE;
#undef TEAM_WHITE
inline constexpr t green = TEAM_GREEN;
#undef TEAM_GREEN
inline constexpr t orange = TEAM_ORANGE;
#undef TEAM_ORANGE
inline constexpr t purple = TEAM_PURPLE;
#undef TEAM_PURPLE
inline constexpr t brown = TEAM_BROWN;
#undef TEAM_BROWN
inline constexpr t gray = TEAM_GRAY;
#undef TEAM_GRAY
#if DEBUG
pure auto
print_color(t x) noexcept
-> std::string {
  switch (x) {
    case blue: return "Blue";
    case red: return "Red";
    case yellow: return "Yellow";
    case black: return "Black";
    case white: return "White";
    case green: return "Green";
    case orange: return "Orange";
    case purple: return "Purple";
    case brown: return "Brown";
    case gray: return "Gray";
    default: return "unrecognized color";
  }
}
#endif
} // namespace team

namespace competition {

namespace phase {
using t = u8;
inline constexpr t round_robin = COMPETITION_PHASE_ROUNDROBIN;
#undef COMPETITION_PHASE_ROUNDROBIN
inline constexpr t playoff = COMPETITION_PHASE_PLAYOFF;
#undef COMPETITION_PHASE_PLAYOFF
} // namespace phase

namespace type {
using t = u8;
inline constexpr t normal = COMPETITION_TYPE_NORMAL;
#undef COMPETITION_TYPE_NORMAL
inline constexpr t challenge_shield = COMPETITION_TYPE_CHALLENGE_SHIELD;
#undef COMPETITION_TYPE_CHALLENGE_SHIELD
inline constexpr t seven_on_seven = COMPETITION_TYPE_7V7;
#undef COMPETITION_TYPE_7V7
inline constexpr t dynamic_ball_handling = COMPETITION_TYPE_DYNAMIC_BALL_HANDLING;
#undef COMPETITION_TYPE_DYNAMIC_BALL_HANDLING
} // namespace type

} // namespace competition

namespace game {
namespace phase {
using t = u8;
inline constexpr t normal = GAME_PHASE_NORMAL;
#undef GAME_PHASE_NORMAL
inline constexpr t penalty = GAME_PHASE_PENALTYSHOOT;
#undef GAME_PHASE_PENALTYSHOOT
inline constexpr t overtime = GAME_PHASE_OVERTIME;
#undef GAME_PHASE_OVERTIME
inline constexpr t timeout = GAME_PHASE_TIMEOUT;
#undef GAME_PHASE_TIMEOUT
} // namespace phase
} // namespace game

namespace state {
using t = u8;
inline constexpr t initial = STATE_INITIAL;
#undef STATE_INITIAL
inline constexpr t ready = STATE_READY;
#undef STATE_READY
inline constexpr t set = STATE_SET;
#undef STATE_SET
inline constexpr t playing = STATE_PLAYING;
#undef STATE_PLAYING
inline constexpr t finished = STATE_FINISHED;
#undef STATE_FINISHED
} // namespace state

namespace set_play {
using t = u8;
inline constexpr t none = SET_PLAY_NONE;
#undef SET_PLAY_NONE
inline constexpr t goal_kick = SET_PLAY_GOAL_KICK;
#undef SET_PLAY_GOAL_KICK
inline constexpr t pushing_free_kick = SET_PLAY_PUSHING_FREE_KICK;
#undef SET_PLAY_GOAL_KICK_OPP
inline constexpr t corner_kick = SET_PLAY_CORNER_KICK;
#undef SET_PLAY_CORNER_KICK
inline constexpr t kick_in = SET_PLAY_KICK_IN;
#undef SET_PLAY_KICK_IN
inline constexpr t penalty_kick = SET_PLAY_PENALTY_KICK;
#undef SET_PLAY_PENALTY_KICK
} // namespace set_play

namespace penalty {
using t = u8;
inline constexpr t none = PENALTY_NONE;
#undef PENALTY_NONE
inline constexpr t illegal_ball_contact = PENALTY_SPL_ILLEGAL_BALL_CONTACT;
#undef PENALTY_SPL_ILLEGAL_BALL_CONTACT
inline constexpr t player_pushing = PENALTY_SPL_PLAYER_PUSHING;
#undef PENALTY_SPL_PLAYER_PUSHING
inline constexpr t illegal_motion_in_set = PENALTY_SPL_ILLEGAL_MOTION_IN_SET;
#undef PENALTY_SPL_ILLEGAL_MOTION_IN_SET
inline constexpr t inactive_player = PENALTY_SPL_INACTIVE_PLAYER;
#undef PENALTY_SPL_INACTIVE_PLAYER
inline constexpr t illegal_position = PENALTY_SPL_ILLEGAL_POSITION;
#undef PENALTY_SPL_ILLEGAL_POSITION
inline constexpr t leaving_field = PENALTY_SPL_LEAVING_THE_FIELD;
#undef PENALTY_SPL_LEAVING_THE_FIELD
inline constexpr t request_pickup = PENALTY_SPL_REQUEST_FOR_PICKUP;
#undef PENALTY_SPL_REQUEST_FOR_PICKUP
inline constexpr t game_stuck = PENALTY_SPL_LOCAL_GAME_STUCK;
#undef PENALTY_SPL_LOCAL_GAME_STUCK
inline constexpr t illegal_position_in_set = PENALTY_SPL_ILLEGAL_POSITION_IN_SET;
#undef PENALTY_SPL_ILLEGAL_POSITION_IN_SET
inline constexpr t substitute = PENALTY_SUBSTITUTE;
#undef PENALTY_SUBSTITUTE
inline constexpr t manual = PENALTY_MANUAL;
#undef PENALTY_MANUAL
} // namespace penalty

} // namespace gamecontroller
} // namespace config

namespace spl {

pure auto
operator==(RobotInfo const& lhs, RobotInfo const& rhs) noexcept -> bool {
  return (
    (lhs.penalty == rhs.penalty) and
    (lhs.secsTillUnpenalised == rhs.secsTillUnpenalised));
}

pure auto
operator==(TeamInfo const& lhs, TeamInfo const& rhs) noexcept
-> bool {
  return (
    (lhs.messageBudget == rhs.messageBudget) and
    (lhs.penaltyShot == rhs.penaltyShot) and
    std::equal(std::begin(lhs.players), std::end(lhs.players), std::begin(rhs.players), std::end(rhs.players)) and
    (lhs.score == rhs.score) and
    (lhs.singleShots == rhs.singleShots) and
    (lhs.teamColour == rhs.teamColour) and
    (lhs.teamNumber == rhs.teamNumber));
}

#if DEBUG

INLINE auto
operator<<(std::ostream& os, RobotInfo const& robot) noexcept
-> std::ostream& {
  if (robot.penalty) { return os << 'P' << +robot.penalty << " for " << +robot.secsTillUnpenalised << 's'; }
  return os << "in";
}

template <u8 N>
INLINE auto
operator<<(std::ostream& os, RobotInfo const (&robots)[N]) noexcept
-> std::ostream& {
  os << '{' << robots[0];
  for (u8 i = 1; i < N; ++i) { os << ", " << robots[i]; }
  return os << '}';
}

INLINE auto
operator<<(std::ostream& os, TeamInfo const& team) noexcept
-> std::ostream& {
  return os << "[Team #" << +team.teamNumber << " (" << ::config::gamecontroller::team::print_color(team.teamColour) << ") with " << +team.score << " point(s), " << +team.messageBudget << " messages left, " << std::bitset<16>{team.singleShots} << " on penalty shots, players " << team.players << ']';
}

pure auto
operator+(TeamInfo const& x) noexcept
-> TeamInfo {
  return x;
}

INLINE auto
operator<<(std::ostream& os, GameControlReturnData const& msg) noexcept
-> std::ostream& {
  os << "[Team " << +msg.teamNum << " Player #" << +msg.playerNum;
  if (msg.fallen) { os << ", FALLEN,"; }
  os << " at (" << msg.pose[0] << ' ' << msg.pose[1] << ' ' << msg.pose[2] << "), ball (" << msg.ball[0] << ' ' << msg.ball[1] << ") (";
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wfloat-equal"
  if (msg.ballAge != -1.F) { return os << "last seen " << msg.ballAge << "s ago)]"; }
#pragma clang diagnostic pop
  return os << "never seen)]";
}

#endif // DEBUG

} // namespace spl
