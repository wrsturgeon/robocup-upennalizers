#pragma once

namespace msg {

namespace spl {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything" // Ignore any errors from SPL code
#include "ext/GameController/examples/c/SPLStandardMessage.h"
#pragma clang diagnostic pop
} // namespace spl

namespace gc {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything" // Ignore any errors from SPL code
#include "ext/GameController/examples/c/RoboCupGameControlData.h"
#pragma clang diagnostic pop
} // namespace gc

} // namespace msg

namespace config {

namespace gc {

inline constexpr u8 max_players = MAX_NUM_PLAYERS;
#undef MAX_NUM_PLAYERS

namespace send {
inline constexpr u16 port = GAMECONTROLLER_DATA_PORT;
#undef GAMECONTROLLER_DATA_PORT
inline constexpr char const* header = GAMECONTROLLER_STRUCT_HEADER;
#undef GAMECONTROLLER_STRUCT_HEADER
inline constexpr u8 version = GAMECONTROLLER_STRUCT_VERSION;
} // namespace send

namespace recv {
inline constexpr u16 port = GAMECONTROLLER_RETURN_PORT;
#undef GAMECONTROLLER_RETURN_PORT
inline constexpr char const* header = GAMECONTROLLER_RETURN_STRUCT_HEADER;
#undef GAMECONTROLLER_RETURN_STRUCT_HEADER
inline constexpr u8 version = GAMECONTROLLER_RETURN_STRUCT_VERSION;
#undef GAMECONTROLLER_RETURN_STRUCT_VERSION
} // namespace recv

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
} // namespace team

namespace competition {

namespace phase {
using t = bool;
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

} // namespace gc

namespace spl {
inline constexpr char const* header = SPL_STANDARD_MESSAGE_STRUCT_HEADER;
#undef SPL_STANDARD_MESSAGE_STRUCT_HEADER
inline constexpr u8 version = SPL_STANDARD_MESSAGE_STRUCT_VERSION;
#undef SPL_STANDARD_MESSAGE_STRUCT_VERSION
inline constexpr u16 data_size = SPL_STANDARD_MESSAGE_DATA_SIZE;
#undef SPL_STANDARD_MESSAGE_DATA_SIZE
} // namespace spl

} // namespace config
