#ifndef CONFIG_GAMECONTROLLER_HPP
#define CONFIG_GAMECONTROLLER_HPP

#include "config/teams.hpp"

#include <algorithm>

#if DEBUG || VERBOSE
#include <bitset>
#endif

namespace spl {
#define RoboCupGameControlData GameControlData
#define RoboCupGameControlReturnData GameControlReturnData
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything" // Ignore any errors from SPL code
#include <RoboCupGameControlData.h> // check compilation args: -isystem so clang-tidy will stfu
#pragma clang diagnostic pop
#undef RoboCupGameControlReturnData
#undef RoboCupGameControlData
} // namespace spl

namespace config {
namespace gamecontroller {

inline constexpr u8 max_players{MAX_NUM_PLAYERS};
#undef MAX_NUM_PLAYERS

namespace color {
using t = u8;
inline constexpr t blue{TEAM_BLUE};
#undef TEAM_BLUE
inline constexpr t red{TEAM_RED};
#undef TEAM_RED
inline constexpr t yellow{TEAM_YELLOW};
#undef TEAM_YELLOW
inline constexpr t black{TEAM_BLACK};
#undef TEAM_BLACK
inline constexpr t white{TEAM_WHITE};
#undef TEAM_WHITE
inline constexpr t green{TEAM_GREEN};
#undef TEAM_GREEN
inline constexpr t orange{TEAM_ORANGE};
#undef TEAM_ORANGE
inline constexpr t purple{TEAM_PURPLE};
#undef TEAM_PURPLE
inline constexpr t brown{TEAM_BROWN};
#undef TEAM_BROWN
inline constexpr t gray{TEAM_GRAY};
#undef TEAM_GRAY
#if DEBUG || VERBOSE
static
std::string
print(t x) {
  try { switch (x) {
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
    default: return "[unrecognized team color " + std::to_string(x) + "]";
  } } catch (...) { std::terminate(); }
}
#endif
} // namespace color

namespace competition {

namespace phase {
using t = u8;
inline constexpr t round_robin{COMPETITION_PHASE_ROUNDROBIN};
#undef COMPETITION_PHASE_ROUNDROBIN
inline constexpr t playoff{COMPETITION_PHASE_PLAYOFF};
#undef COMPETITION_PHASE_PLAYOFF
#if DEBUG || VERBOSE
static
std::string
print(t x)
noexcept {
  try { switch (x) {
    case round_robin: return "Round-Robin";
    case playoff: return "Playoff";
    default: return "[unrecognized competition phase " + std::to_string(x) + "]";
  } } catch (...) { std::terminate(); }
}
#endif
} // namespace phase

namespace type {
using t = u8;
inline constexpr t normal{COMPETITION_TYPE_NORMAL};
#undef COMPETITION_TYPE_NORMAL
inline constexpr t challenge_shield{COMPETITION_TYPE_CHALLENGE_SHIELD};
#undef COMPETITION_TYPE_CHALLENGE_SHIELD
inline constexpr t seven_on_seven{COMPETITION_TYPE_7V7};
#undef COMPETITION_TYPE_7V7
inline constexpr t dynamic_ball_handling{COMPETITION_TYPE_DYNAMIC_BALL_HANDLING};
#undef COMPETITION_TYPE_DYNAMIC_BALL_HANDLING
#if DEBUG || VERBOSE
static
std::string
print(t x)
noexcept {
  try { switch (x) {
    case normal: return "Normal";
    case challenge_shield: return "Challenge Shield";
    case seven_on_seven: return "7v7";
    case dynamic_ball_handling: return "Dynamic Ball Handling";
    default: return "[unrecognized competition type " + std::to_string(x) + "]";
  } } catch (...) { std::terminate(); }
}
#endif
} // namespace type

} // namespace competition

namespace game {
namespace phase {
using t = u8;
inline constexpr t normal{GAME_PHASE_NORMAL};
#undef GAME_PHASE_NORMAL
inline constexpr t penalty{GAME_PHASE_PENALTYSHOOT};
#undef GAME_PHASE_PENALTYSHOOT
inline constexpr t overtime{GAME_PHASE_OVERTIME};
#undef GAME_PHASE_OVERTIME
inline constexpr t timeout{GAME_PHASE_TIMEOUT};
#undef GAME_PHASE_TIMEOUT
#if DEBUG || VERBOSE
static
std::string
print(t x)
noexcept {
  try { switch (x) {
    case normal: return "Normal";
    case penalty: return "Penalty";
    case overtime: return "Overtime";
    case timeout: return "Timeout";
    default: return "[unrecognized game phase " + std::to_string(x) + "]";
  } } catch (...) { std::terminate(); }
}
#endif
} // namespace phase
} // namespace game

namespace state {
using t = u8;
inline constexpr t initial{STATE_INITIAL};
#undef STATE_INITIAL
inline constexpr t ready{STATE_READY};
#undef STATE_READY
inline constexpr t set{STATE_SET};
#undef STATE_SET
inline constexpr t playing{STATE_PLAYING};
#undef STATE_PLAYING
inline constexpr t finished{STATE_FINISHED};
#undef STATE_FINISHED
#if DEBUG || VERBOSE
static
std::string
print(t x)
noexcept {
  try { switch (x) {
    case initial: return "Initial";
    case ready: return "Ready";
    case set: return "Set";
    case playing: return "Playing";
    case finished: return "Finished";
    default: return "[unrecognized state " + std::to_string(x) + "]";
  } } catch (...) { std::terminate(); }
}
#endif
} // namespace state

namespace set_play {
using t = u8;
inline constexpr t none{SET_PLAY_NONE};
#undef SET_PLAY_NONE
inline constexpr t goal_kick{SET_PLAY_GOAL_KICK};
#undef SET_PLAY_GOAL_KICK
inline constexpr t pushing_free_kick{SET_PLAY_PUSHING_FREE_KICK};
#undef SET_PLAY_GOAL_KICK_OPP
inline constexpr t corner_kick{SET_PLAY_CORNER_KICK};
#undef SET_PLAY_CORNER_KICK
inline constexpr t kick_in{SET_PLAY_KICK_IN};
#undef SET_PLAY_KICK_IN
inline constexpr t penalty_kick{SET_PLAY_PENALTY_KICK};
#undef SET_PLAY_PENALTY_KICK
#if DEBUG || VERBOSE
static
std::string
print(t x)
noexcept {
  try { switch (x) {
    case none: return "None";
    case goal_kick: return "Goal Kick";
    case pushing_free_kick: return "Pushing Free Kick";
    case corner_kick: return "Corner Kick";
    case kick_in: return "Kick In";
    case penalty_kick: return "Penalty Kick";
    default: return "[unrecognized set-play " + std::to_string(x) + "]";
  } } catch (...) { std::terminate(); }
}
#endif
} // namespace set_play

namespace penalty {
using t = u8;
inline constexpr t none{PENALTY_NONE};
#undef PENALTY_NONE
inline constexpr t illegal_ball_contact{PENALTY_SPL_ILLEGAL_BALL_CONTACT};
#undef PENALTY_SPL_ILLEGAL_BALL_CONTACT
inline constexpr t player_pushing{PENALTY_SPL_PLAYER_PUSHING};
#undef PENALTY_SPL_PLAYER_PUSHING
inline constexpr t illegal_motion_in_set{PENALTY_SPL_ILLEGAL_MOTION_IN_SET};
#undef PENALTY_SPL_ILLEGAL_MOTION_IN_SET
inline constexpr t inactive_player{PENALTY_SPL_INACTIVE_PLAYER};
#undef PENALTY_SPL_INACTIVE_PLAYER
inline constexpr t illegal_position{PENALTY_SPL_ILLEGAL_POSITION};
#undef PENALTY_SPL_ILLEGAL_POSITION
inline constexpr t leaving_field{PENALTY_SPL_LEAVING_THE_FIELD};
#undef PENALTY_SPL_LEAVING_THE_FIELD
inline constexpr t request_pickup{PENALTY_SPL_REQUEST_FOR_PICKUP};
#undef PENALTY_SPL_REQUEST_FOR_PICKUP
inline constexpr t game_stuck{PENALTY_SPL_LOCAL_GAME_STUCK};
#undef PENALTY_SPL_LOCAL_GAME_STUCK
inline constexpr t illegal_position_in_set{PENALTY_SPL_ILLEGAL_POSITION_IN_SET};
#undef PENALTY_SPL_ILLEGAL_POSITION_IN_SET
inline constexpr t substitute{PENALTY_SUBSTITUTE};
#undef PENALTY_SUBSTITUTE
inline constexpr t manual{PENALTY_MANUAL};
#undef PENALTY_MANUAL
#if DEBUG || VERBOSE
static
std::string
print(t x)
noexcept {
  try { switch (x) {
    case none: return "None";
    case illegal_ball_contact: return "Illegal Ball Contact";
    case player_pushing: return "Pushing";
    case illegal_motion_in_set: return "Illegal Motion in Set";
    case inactive_player: return "Inactive Player";
    case illegal_position: return "Illegal Position";
    case leaving_field: return "Leaving the Field";
    case request_pickup: return "Request Pickup";
    case game_stuck: return "Game Stuck";
    case illegal_position_in_set: return "Illegal Position in Set";
    case substitute: return "Substitute";
    case manual: return "Manual Penalty";
    default: return "[unrecognized penalty " + std::to_string(x) + "]";
  } } catch (...) { std::terminate(); }
}
#endif
} // namespace penalty

} // namespace gamecontroller
} // namespace config

namespace spl {

constexpr
bool
operator==(RobotInfo const& lhs, RobotInfo const& rhs)
noexcept {
  return (
    (lhs.penalty == rhs.penalty) and
    (lhs.secsTillUnpenalised == rhs.secsTillUnpenalised));
}

constexpr
bool
operator==(TeamInfo const& lhs, TeamInfo const& rhs)
noexcept {
  return (
    (lhs.messageBudget == rhs.messageBudget) and
    (lhs.penaltyShot == rhs.penaltyShot) and
    std::equal(std::begin(lhs.players), std::end(lhs.players), std::begin(rhs.players), std::end(rhs.players)) and
    (lhs.score == rhs.score) and
    (lhs.singleShots == rhs.singleShots) and
    (lhs.teamColour == rhs.teamColour) and
    (lhs.teamNumber == rhs.teamNumber));
}

#if DEBUG || VERBOSE

static
std::ostream&
operator<<(std::ostream& os, RobotInfo const& robot)
noexcept {
  try { switch (robot.penalty) {
    case config::gamecontroller::penalty::none: return os << "in";
    case config::gamecontroller::penalty::substitute: return os << "sub";
    default: return os << config::gamecontroller::penalty::print(robot.penalty) << " for " << +robot.secsTillUnpenalised << 's';
  } } catch (...) { std::terminate(); }
}

template <u8 N>
static
std::ostream&
operator<<(std::ostream& os, RobotInfo const (&robots)[N])
noexcept {
  os << '{' << robots[0];
  for (u8 i{1}; i < N; ++i) { os << ", " << robots[i]; }
  return os << '}';
}

static
std::ostream&
operator<<(std::ostream& os, TeamInfo const& team)
noexcept {
  return os << '[' << config::gamecontroller::team::name(team.teamNumber) << " (" << ::config::gamecontroller::color::print(team.teamColour) << ") with " << +team.score << " point(s), " << +team.messageBudget << " messages left, " << std::bitset<16>{team.singleShots} << " on penalty shots, players " << team.players << ']';
}

// static
// std::ostream&
// operator<<(std::ostream& os, GameControlReturnData const& msg)
// noexcept {
//   os << '[' << config::gamecontroller::team::number(msg.teamNum) << " Player #" << +msg.playerNum;
//   if (msg.fallen) { os << ", FALLEN,"; }
//   os << " at (" << msg.pose[0] << ' ' << msg.pose[1] << ' ' << msg.pose[2] << "), ball (" << msg.ball[0] << ' ' << msg.ball[1] << ") (";
// #pragma clang diagnostic push
// #pragma clang diagnostic ignored "-Wfloat-equal"
//   if (msg.ballAge != -1.F) { return os << "last seen " << msg.ballAge << "s ago)]"; }
// #pragma clang diagnostic pop
//   return os << "never seen)]";
// }

#endif // DEBUG || VERBOSE

} // namespace spl

#endif // CONFIG_GAMECONTROLLER_HPP
