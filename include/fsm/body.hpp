#ifndef FSM_BODY_HPP
#define FSM_BODY_HPP

// See legacy/Player/BodyFSM/BodyFSM.lua

#include "fsm/register.hpp"

REGISTER_FSM_EVENTS(Body,
  "coach",
  "done",
  "done_goalie",
  "ball",
  "ball_close",
  "ball_far",
  "ball_found",
  "ball_free",
  "ball_goalie",
  "ball_lost",
  "ball_orbit",
  "done",
  "fall",
  "free_kick",
  "goalie",
  "kick",
  "our_turn",
  "player",
  "ready",
  "reposition",
  "role_change",
  "timeout",
  "timeout_goalie",
  "track_team_ball",
  "walk_kick")

REGISTER_FSM_STATES(Body,
  "anticipate",
  "approach",
  "chase",
  "coach",
  "dive",
  "dribble",
  "go_to_center",
  "handle_kickoff",
  "idle",
  "kick",
  "orbit",
  "position",
  "position_goalie",
  "ready",
  "ready_move",
  "search",
  "search_goalie",
  "search_team",
  "start",
  "still",
  "stop",
  "unpenalized",
  "walk_kick")

// NOLINTBEGIN(bugprone-branch-clone,hicpp-multiway-paths-covered)

REGISTER_FSM_TRANSITION_EVENT(Body, goalie,
  TRANSITION(start, anticipate)
  TRANSITION(position, position_goalie)
  TRANSITION(search, position_goalie))

REGISTER_FSM_TRANSITION_EVENT(Body, player,
  TRANSITION(start, handle_kickoff)
  TRANSITION(position_goalie, position)
  TRANSITION(anticipate, position))

REGISTER_FSM_TRANSITION_EVENT(Body, coach,
  TRANSITION(start, anticipate))

REGISTER_FSM_TRANSITION_EVENT(Body, ball_free,
  TRANSITION(handle_kickoff, position))

REGISTER_FSM_TRANSITION_EVENT(Body, our_turn,
  TRANSITION(handle_kickoff, position))

REGISTER_FSM_TRANSITION_EVENT(Body, walk_kick,
  TRANSITION(handle_kickoff, walk_kick)
  TRANSITION(approach, walk_kick))

REGISTER_FSM_TRANSITION_EVENT(Body, timeout,
  TRANSITION(position, position)
  TRANSITION(search, search_team)
  TRANSITION(go_to_center, search_team)
  TRANSITION(search_team, position)
  TRANSITION(orbit, position)
  TRANSITION(approach, position)
  TRANSITION(kick, position)
  TRANSITION(dribble, position)
  TRANSITION(still, position)
  TRANSITION(position_goalie, position_goalie)
  TRANSITION(anticipate, anticipate)
  TRANSITION(dive, search)
  TRANSITION(search_goalie, position_goalie))

REGISTER_FSM_TRANSITION_EVENT(Body, ball_lost,
  TRANSITION(position, search)
  TRANSITION(orbit, search)
  TRANSITION(approach, search)
  TRANSITION(still, search)
  TRANSITION(position_goalie, search_goalie)
  TRANSITION(chase, position_goalie))

REGISTER_FSM_TRANSITION_EVENT(Body, ball_close,
  TRANSITION(position, orbit)
  TRANSITION(position_goalie, chase)
  TRANSITION(anticipate, chase)
  TRANSITION(chase, approach))

REGISTER_FSM_TRANSITION_EVENT(Body, done,
  TRANSITION(position, approach)
  TRANSITION(unpenalized, position)
  TRANSITION(go_to_center, search_team)
  TRANSITION(search_team, search)
  TRANSITION(orbit, approach)
  TRANSITION(kick, position)
  TRANSITION(walk_kick, position)
  TRANSITION(dribble, position)
  TRANSITION(ready, ready_move)
  TRANSITION(search_goalie, position_goalie))

REGISTER_FSM_TRANSITION_EVENT(Body, fall,
  TRANSITION(position, position)
  TRANSITION(approach, position)
  TRANSITION(kick, position)
  TRANSITION(dribble, position)
  TRANSITION(ready_move, ready_move)
  TRANSITION(still, position)
  TRANSITION(position_goalie, position_goalie)
  TRANSITION(chase, position_goalie)
  TRANSITION(dive, chase))

REGISTER_FSM_TRANSITION_EVENT(Body, track_team_ball,
  TRANSITION(position, still))

REGISTER_FSM_TRANSITION_EVENT(Body, ball,
  TRANSITION(search, position)
  TRANSITION(search_team, position)
  TRANSITION(search_goalie, chase))

REGISTER_FSM_TRANSITION_EVENT(Body, ball_goalie,
  TRANSITION(search, chase))

REGISTER_FSM_TRANSITION_EVENT(Body, timeout_goalie,
  TRANSITION(search, position_goalie))

REGISTER_FSM_TRANSITION_EVENT(Body, ball_found,
  TRANSITION(go_to_center, position))

REGISTER_FSM_TRANSITION_EVENT(Body, team_ball,
  TRANSITION(search_team, position))

REGISTER_FSM_TRANSITION_EVENT(Body, ball_far,
  TRANSITION(orbit, position)
  TRANSITION(approach, position)
  TRANSITION(chase, position_goalie))

REGISTER_FSM_TRANSITION_EVENT(Body, free_kick,
  TRANSITION(orbit, position)
  TRANSITION(approach, position))

REGISTER_FSM_TRANSITION_EVENT(Body, ball_orbit,
  TRANSITION(approach, orbit))

REGISTER_FSM_TRANSITION_EVENT(Body, reposition,
  TRANSITION(kick, approach)
  TRANSITION(dribble, approach))

REGISTER_FSM_TRANSITION_EVENT(Body, role_change,
  TRANSITION(still, position))

REGISTER_FSM_TRANSITION_EVENT(Body, dive,
  TRANSITION(anticipate, dive))

REGISTER_FSM_TRANSITION_EVENT(Body, reanticipate,
  TRANSITION(dive, anticipate))

// NOLINTEND(bugprone-branch-clone,hicpp-multiway-paths-covered)

VERIFY_FSM_REGISTRATION(Body)

#endif // FSM_BODY_HPP
