#pragma once

namespace msg {

namespace spl {
#include "ext/GameController/examples/c/SPLStandardMessage.h"
} // namespace spl

namespace gamecontroller {
#include "ext/GameController/examples/c/RoboCupGameControlData.h"
} // namespace gamecontroller

} // namespace msg

namespace config {
namespace msg {

//%%%%%%%%%%%%%%%% THE MOST IMPORTANT NUMBER
inline constexpr u16 max_packets = 1200; // Managed automatically in msg::spl::TeamInfo::messageBudget (f@%$ing Java case)
inline constexpr u16 max_packets_per_extra_minute = 60; // This...should be also? ^^^
//%%%%%%%%%%%%%%%%

namespace gamecontroller {

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
inline constexpr u8 blue = TEAM_BLUE;
#undef TEAM_BLUE
inline constexpr u8 red = TEAM_RED;
#undef TEAM_RED
inline constexpr u8 yellow = TEAM_YELLOW;
#undef TEAM_YELLOW
inline constexpr u8 black = TEAM_BLACK;
#undef TEAM_BLACK
inline constexpr u8 white = TEAM_WHITE;
#undef TEAM_WHITE
inline constexpr u8 green = TEAM_GREEN;
#undef TEAM_GREEN
inline constexpr u8 orange = TEAM_ORANGE;
#undef TEAM_ORANGE
inline constexpr u8 purple = TEAM_PURPLE;
#undef TEAM_PURPLE
inline constexpr u8 brown = TEAM_BROWN;
#undef TEAM_BROWN
inline constexpr u8 gray = TEAM_GRAY;
#undef TEAM_GRAY
} // namespace team

namespace competition {

namespace phase {
inline constexpr u8 round_robin = COMPETITION_PHASE_ROUNDROBIN;
#undef COMPETITION_PHASE_ROUNDROBIN
inline constexpr u8 playoff = COMPETITION_PHASE_PLAYOFF;
#undef COMPETITION_PHASE_PLAYOFF
} // namespace phase

namespace type {
inline constexpr u8 normal = COMPETITION_TYPE_NORMAL;
#undef COMPETITION_TYPE_NORMAL
inline constexpr u8 challenge_shield = COMPETITION_TYPE_CHALLENGE_SHIELD;
#undef COMPETITION_TYPE_CHALLENGE_SHIELD
inline constexpr u8 seven_on_seven = COMPETITION_TYPE_7V7;
#undef COMPETITION_TYPE_7V7
inline constexpr u8 dynamic_ball_handling = COMPETITION_TYPE_DYNAMIC_BALL_HANDLING;
#undef COMPETITION_TYPE_DYNAMIC_BALL_HANDLING
} // namespace type

} // namespace competition

namespace game {
namespace phase {
inline constexpr u8 normal = GAME_PHASE_NORMAL;
#undef GAME_PHASE_NORMAL
inline constexpr u8 penalty = GAME_PHASE_PENALTYSHOOT;
#undef GAME_PHASE_PENALTYSHOOT
inline constexpr u8 overtime = GAME_PHASE_OVERTIME;
#undef GAME_PHASE_OVERTIME
inline constexpr u8 timeout = GAME_PHASE_TIMEOUT;
#undef GAME_PHASE_TIMEOUT
} // namespace phase
} // namespace game

namespace state {
inline constexpr u8 initial = STATE_INITIAL;
#undef STATE_INITIAL
inline constexpr u8 ready = STATE_READY;
#undef STATE_READY
inline constexpr u8 set = STATE_SET;
#undef STATE_SET
inline constexpr u8 playing = STATE_PLAYING;
#undef STATE_PLAYING
inline constexpr u8 finished = STATE_FINISHED;
#undef STATE_FINISHED
} // namespace state

namespace set_play {
inline constexpr u8 none = SET_PLAY_NONE;
#undef SET_PLAY_NONE
inline constexpr u8 goal_kick = SET_PLAY_GOAL_KICK;
#undef SET_PLAY_GOAL_KICK
inline constexpr u8 pushing_free_kick = SET_PLAY_PUSHING_FREE_KICK;
#undef SET_PLAY_GOAL_KICK_OPP
inline constexpr u8 corner_kick = SET_PLAY_CORNER_KICK;
#undef SET_PLAY_CORNER_KICK
inline constexpr u8 kick_in = SET_PLAY_KICK_IN;
#undef SET_PLAY_KICK_IN
inline constexpr u8 penalty_kick = SET_PLAY_PENALTY_KICK;
#undef SET_PLAY_PENALTY_KICK
} // namespace set_play

namespace penalty {
inline constexpr u8 none = PENALTY_NONE;
#undef PENALTY_NONE
inline constexpr u8 illegal_ball_contact = PENALTY_SPL_ILLEGAL_BALL_CONTACT;
#undef PENALTY_SPL_ILLEGAL_BALL_CONTACT
inline constexpr u8 player_pushing = PENALTY_SPL_PLAYER_PUSHING;
#undef PENALTY_SPL_PLAYER_PUSHING
inline constexpr u8 illegal_motion_in_set = PENALTY_SPL_ILLEGAL_MOTION_IN_SET;
#undef PENALTY_SPL_ILLEGAL_MOTION_IN_SET
inline constexpr u8 inactive_player = PENALTY_SPL_INACTIVE_PLAYER;
#undef PENALTY_SPL_INACTIVE_PLAYER
inline constexpr u8 illegal_position = PENALTY_SPL_ILLEGAL_POSITION;
#undef PENALTY_SPL_ILLEGAL_POSITION
inline constexpr u8 leaving_field = PENALTY_SPL_LEAVING_THE_FIELD;
#undef PENALTY_SPL_LEAVING_THE_FIELD
inline constexpr u8 request_pickup = PENALTY_SPL_REQUEST_FOR_PICKUP;
#undef PENALTY_SPL_REQUEST_FOR_PICKUP
inline constexpr u8 game_stuck = PENALTY_SPL_LOCAL_GAME_STUCK;
#undef PENALTY_SPL_LOCAL_GAME_STUCK
inline constexpr u8 illegal_position_in_set = PENALTY_SPL_ILLEGAL_POSITION_IN_SET;
#undef PENALTY_SPL_ILLEGAL_POSITION_IN_SET
inline constexpr u8 substitute = PENALTY_SUBSTITUTE;
#undef PENALTY_SUBSTITUTE
inline constexpr u8 manual = PENALTY_MANUAL;
#undef PENALTY_MANUAL
} // namespace penalty

} // namespace gamecontroller

namespace spl {
inline constexpr char const* header = SPL_STANDARD_MESSAGE_STRUCT_HEADER;
#undef SPL_STANDARD_MESSAGE_STRUCT_HEADER
inline constexpr u8 version = SPL_STANDARD_MESSAGE_STRUCT_VERSION;
#undef SPL_STANDARD_MESSAGE_STRUCT_VERSION
inline constexpr u16 data_size = SPL_STANDARD_MESSAGE_DATA_SIZE;
#undef SPL_STANDARD_MESSAGE_DATA_SIZE
} // namespace spl

} // namespace msg
} // namespace config
