module(..., package.seeall);

require('Config');
require('Body');
require('Comm');
require('Speak');
require('vector');
require('util')
require('serialization');
require('wcm');
require('vcm');
require('gcm');
require('utilMsg')

-- Zaini edits to TeamSPL.lua
-- Attacker ETA utilizes "LAST SEEN BALL" more
-- TeamBall utilizes a measure for how confident am I that that is the ball
-- How confident am I that I am where I am
-- Measure for how much I trust this robot (send it to all robots).
-- Problem right now is that we have a local (dont trust me) and we tell others to use it on us
-- I want a leaky accumulator that does that off of both the local and the non-local value.
--
-- Non-Local things are:
-- ball validation (on field? in goal?)
-- ball verification(Do I see ball and he sees it somewhere else?
-- Are multiple robots close enough but cant see the ball (tough measurement cuz robots blocking the way),
-- do I know where the ball is but he sees it differently (fouls are definites !!!!)?)
--
-- This value gets sent from robot to robot, averaged, and then accumulated with the last value. Since 1 message per second we can make it a harmonic series
-- Each robot calculates a value, sends it and each value is only influenced by one robot.
-- I feel Goalie wont be too helpful with this though, maybe when he knows its a goalkick, or for the foul stuff. Any robot being alive helps
--
--
--

local log = require 'log';
if Config.log.enableLogFiles then
    log.outfile = (Config.log.worldFile);
end
log.level = Config.log.logLevel;

--Player ID: 1 to 5
--Role enum we used before
ROLE_GOALIE = 0
ROLE_ATTACKER = 1
ROLE_DEFENDER = 2
ROLE_SUPPORTER = 3
ROLE_DEFENDER2 = 4
ROLE_LOST = 5
ROLE_COACH = 6  -- COACH DOESNT EXIST ANYMORE

--New Teamplay code
--That uses new SPL standardized team message
--Now coach is not even allowed to use the same comm!


local state = utilMsg.get_default_state()

--------------------------------------------------------------
Comm.init(Config.dev.ip_wireless,Config.dev.ip_wireless_port);
log.info('Receiving Team Message From',Config.dev.ip_wireless);
playerID = gcm.get_team_player_id();
msgTimeout = Config.team.msgTimeout;
nonAttackerPenalty = Config.team.nonAttackerPenalty;
nonDefenderPenalty = Config.team.nonDefenderPenalty;
fallDownPenalty = Config.team.fallDownPenalty;
ballLostPenalty = Config.team.ballLostPenalty;
walkSpeed = Config.team.walkSpeed or 0.1;
turnSpeed = Config.team.turnSpeed;
tLost = Config.fsm.bodyPosition.tLost;
attackerBallThresh = 0.6;
robot_ballscore = {}

goalie_ball={0,0,0};
role = gcm.get_team_role();

cidx = 1

states = {};
states[playerID] = state;

foulLoc = {};
foulRad = 0.8;


--We maintain pose of all robots
--For obstacle avoidance
poses={};
player_roles=vector.zeros(10);
t_poses=vector.zeros(10);
tLastMessage = 0;
tLastSent = Body.get_time()
send_fps = Config.send_fps or 1

intConf = 1
extConf = 1


function recv_msgs_new_comm()
  --For team communication in game
  if Config.dev.comm == 'TeamComm' then
     local msg = Comm.receive();
     local count;
     while msg do
					 t = utilMsg.convert_state_std_to_penn(msg);
           if t and (t.teamNumber) and (t.id) then
              tLastMessage = Body.get_time();
              if t.id ~= playerID then
                 poses[t.id]=t.pose;
                 player_roles[t.id]=t.role;
                 t_poses[t.id]=Body.get_time();
                 t.tReceive = Body.get_time();
                 t.labelB = {}; --Kill labelB information
                 states[t.id] = t;
              end
           end
           msg=Comm.receive()
     end --end while
  --For team comm in webot
  elseif Config.dev.comm == 'WebotsComm' then
     while (Comm.size() > 0) do
           local msg = Comm.receive();
           if msg and #msg==14 then
              --THIS IS BALL POSITION MESSAGE
              ball_gpsx=(tonumber(string.sub(msg,2,6))-5)*2;
              ball_gpsy=(tonumber(string.sub(msg,8,12))-5)*2;
--              if playerID ~= 2 then
              wcm.set_robot_gps_ball({ball_gpsx,ball_gpsy,0});
--              else
--                wcm.set_robot_gps_ball({-ball_gpsx,-ball_gpsy,0});
--              end
              --print("Ball gps pos:",ball_gpsx,ball_gpsy)
           elseif msg then
                  t = serialization.deserialize(msg);
                  if t and (t.teamNumber) and (t.id) then
                     tLastMessage = Body.get_time();
                     if t.id ~= playerID then
                        poses[t.id]=t.pose;
                        player_roles[t.id]=t.role;
                        t_poses[t.id]=Body.get_time();
                     end
                     if (t.teamNumber == state.teamNumber) and
                        (t.id ~= playerID) then
                        t.tReceive = Body.get_time();
                        t.labelB = {}; --Kill labelB information
                        states[t.id] = t;
                     end
                  end --end if
           end --end elseif
     end --end while
  end --end elseif
end --end function


--Rule of thumb is to trust everyone untill you know not to trust them.
--This function adds up everyone's confidence together.

function update_team_player_confidence()

  confidences = vector.zeros(5);
    for id1 = 1, 5 do
      for id2 = 1, 5 do
        if (not states[id1]) or (states[id1].penalty > 0) or (t - states[id1].tReceive > msgTimeout) or (states[id1].role == ROLE_LOST) then
          confidences[id2] = confidences[id2] + 1;
        else
          confidences[id2] = confidences[id2] + states[id1].teamConfidence[id2];
        end
      end
    end

  wcm.set_team_total_confidence(confidences);
end

--Updates my local confidence in other players

function update_local_player_confidence()

  for id = 1, 5 do
    if not states[id] or (states[id].penalty > 0) or (t - states[id].tReceive > msgTimeout) or (states[id].role == ROLE_LOST) then
      reset_local_player_confidence(id);
    end
  end

  confidences = wcm.get_team_my_confidence();

  for id,state in pairs(states) do
    if (not states[id] or (state.penalty > 0) or (t - state.tReceive > msgTimeout) or (state.role == ROLE_LOST)) then
      --for now this is handled above, maybe we can think of something else?
      print(id)
    else
      id = state.id;

      temp = 1;
      temp2 = 1;

    --right now everything is based on ball positioning, so make sure ball isnt super old.

      if (state.ball.t_seen <= 1) then

        local ball_global = {state.ball.x, state.ball.y};
      -- Validation

      --Is the ball in reasonable field measurement (so field plus or minus 0.2-0.5 meters)
        if(math.abs(ball_global[1]) >  Config.world.xLineBoundary + 0.5 or math.abs(ball_global[2]) > Config.world.yLineBoundary + 0.5) then
          temp = temp - 0.8;
        elseif(math.abs(ball_global[1]) >  Config.world.xLineBoundary + 0.2 or math.abs(ball_global[2]) > Config.world.yLineBoundary + 0.2) then
          temp = temp - 0.4;
        end


      -- Verification

      --If we're in foul, is the ball where we expect it to be?

        local pose = wcm.get_pose();
        local ball = wcm.get_ball();
        local ball_global = {state.ball.x, state.ball.y};



        if(wcm.get_kick_freeKick() ~=0) then
          if(wcm.get_obstacle_foulType() == 1) then
            r1 = math.sqrt((ball_global[1]-Config.world.spot[1][1])^2 + (ball_global[2]-Config.world.Lcorner[5][2])^2);
            r2 = math.sqrt((ball_global[1]-Config.world.spot[1][1])^2 + (ball_global[2]-Config.world.Lcorner[6][2])^2);
            if(r1 > 1 and r2 > 1) then
              temp = temp - 0.8
            elseif(r1 > 0.5 and r2 > 0.5) then
              temp = temp - 0.4
            end
          elseif(wcm.get_obstacle_foulType() == 2) then
            r1 = math.sqrt((ball_global[1]-Config.world.spot[2][1])^2 + (ball_global[2]-Config.world.Lcorner[7][2])^2);
            r2 = math.sqrt((ball_global[1]-Config.world.spot[2][1])^2 + (ball_global[2]-Config.world.Lcorner[8][2])^2);
            if(r1 > 1 and r2 > 1) then
              temp = temp - 0.8
            elseif(r1 > 0.5 and r2 > 0.5) then
              temp = temp - 0.4
            end
          elseif(wcm.get_obstacle_foulType() == 5) then
            r1 = math.sqrt((ball_global[1]-Config.world.Lcorner[1][1])^2 + (ball_global[2]-Config.world.Lcorner[1][2])^2);
            r2 = math.sqrt((ball_global[1]-Config.world.Lcorner[2][1])^2 + (ball_global[2]-Config.world.Lcorner[2][2])^2);
            if(r1 > 1 and r2 > 1) then
              temp = temp - 0.8
            elseif(r1 > 0.5 and r2 > 0.5) then
              temp = temp - 0.4
            end
          elseif(wcm.get_obstacle_foulType() == 6) then
            r1 = math.sqrt((ball_global[1]-Config.world.Lcorner[3][1])^2 + (ball_global[2]-Config.world.Lcorner[3][2])^2);
            r2 = math.sqrt((ball_global[1]-Config.world.Lcorner[4][1])^2 + (ball_global[2]-Config.world.Lcorner[4][2])^2);
            if(r1 > 1 and r2 > 1) then
              temp = temp - 0.8
            elseif(r1 > 0.5 and r2 > 0.5) then
              temp = temp - 0.4
            end
          elseif(wcm.get_obstacle_foulType() == 7 or wcm.get_obstacle_foulType() == 8) then
            r1 = (ball_global[2]-Config.world.Lcorner[3][2]);
            r2 = (ball_global[2]-Config.world.Lcorner[4][2]);
            print(ball_global[1], ball_global[2])
            if(r1 > 1 and r2 > 1) then
              temp = temp - 0.8
            elseif(r1 > 0.5 and r2 > 0.5) then
              temp = temp - 0.4
            end


            if(math.abs(ball_global[2]) < Config.world.yLineBoundary-1) then
              temp = temp - 0.8;
            elseif(math.abs(ball_global[2]) < Config.world.yLineBoundary-0.4) then
              temp = temp - 0.3;
            end
          end
      end

      -- Now for the external dissonance

        local ball = wcm.get_ball();
        local my_ball_global = {ball.x, ball.y};
        local ball_global = {state.ball.x, state.ball.y};


        ballDif = ((my_ball_global[1]-ball_global[1])^2 + (my_ball_global[2]-ball_global[2])^2)
        if ballDif > 1.75 then
          temp2 = 0;
        elseif ballDif > 1 then
          temp2 = temp2 - 0.8;
        elseif ballDif > 0.5 then
          temp2 = temp2 - 0.3;
        end


      end
      temp = math.max(temp, 0)
      temp2 = math.max(temp2, 0)
      confidences[id] = temp2*0.1 + 0.9*confidences[id];
      if( playerID == id) then
        intConf = temp;
      end
      --print("I trust ", id, "this much: ", confidences[id]);
    end


  end

  wcm.set_team_my_confidence(confidences);
end

function reset_local_player_confidence(id)
  confidences = wcm.get_team_my_confidence();
  confidences[id] = 1;
  wcm.set_team_my_confidence(confidences);
end



function entry()
  if Config.dev.comm=='TeamComm' or Config.dev.comm=='WebotsComm'then
  else
    log.error("!!! ERROR: SHOULD USE TEAMCOMM !!!")
    return
  end

end
---------------------------------------
--[[prevMessage = '';
currentMessage = '';
messageTime = 0;
function readCoachMessage()
    --print('gcm.coachMessage '..gcm.get_game_coachMessage());
    currentMessage = gcm.get_game_coachMessage();
    if (currentMessage ~= prevMessage) then
        msg = util.split(currentMessage, " ");
        messageTime = Body.get_time();
        gcm.set_game_coachMessageTime(messageTime);
        prevMessage = currentMessage;
    else
        msg = nil;
    end
    if (msg ~= nil) then
        if (#msg > 1 and msg[1] ~= no) then
            coach_fix_flip(msg);
        end
    end
        elseif (msg[2] == 'ball') then
        elseif (msg[3] == 'ball') then
        elseif (msg[1] == 'in') then
end]]--
---------------------------------------
--[[function coach_fix_flip(msg)
    local pose = wcm.get_pose();
    local ball = wcm.get_ball();
    local ball_global = util.pose_global({ball.x,ball.y,0},{pose.x,pose.y,pose.a});
    local t = Body.get_time();
    local messageTime = gcm.get_game_coachMessageTime();

    if (t - messageTime < flip_threshold_t and t - ball.t < flip_threshold_t) then
        if (msg[2] == 'ball' and #msg > 7) then  --ball is to the left, ball global x should be negative
            if (ball_global[1] > 1.5 and Config.vision.coach.home_left) then  --if ball_global is positive, then robot is flipped
                print('====================coach is flipping other robots========================');
                wcm.set_robot_flipped(1);
                Speak.talk('coach is flipping the other robots');
	    elseif (ball_global[1] < - 1.5 and not Config.vision.coach.home_left) then
		wcm.set_robot_flipped(1);
	    end
        elseif (msg[3] == 'ball' and #msg > 8) then  --ball is to the right, ball global x should be positive
            if (ball_global[1] < -1.5 and Config.vision.coach.home_left) then  --if ball_global is negative, then robot is flipped
                print('====================coach is flipping other robots========================');
                wcm.set_robot_flipped(1);
                Speak.talk('coach is flipping the other robots');
	    elseif (ball_global[1] > 1.5 and not Config.vision.coach.home_left)then
		wcm.set_robot_flipped(1);
	    end
        end
    end
end]]--
---------------------------------------


function build_state()

  state.time = Body.get_time();
  state.teamNumber = gcm.get_team_number();
  state.teamColor = gcm.get_team_color();
  state.pose = wcm.get_pose();
  state.ball = wcm.get_ball();
  state.ball.t_seen = Body.get_time() - state.ball.t  --added
  state.role = role;
  state.attackBearing = wcm.get_attack_bearing();
  state.battery_level = wcm.get_robot_battery_level();
  --put emergency stop penalty in
  if wcm.get_robot_is_fall_down() == 1 then
    state.fall=1;
  else
    state.fall=0;
  end
  if gcm.in_penalty() then
    state.penalty = 1
    for id = 1,5 do
      reset_local_player_confidence(id);
    end
  else
    state.penalty = 0
  end
  state.gc_latency=gcm.get_game_gc_latency();
  state.tm_latency=Body.get_time()-tLastMessage;
  --the previous line crashed once. This is a temporary hack - Dickens
  state.body_state = ' '
  state.walkingTo = gcm.get_game_walkingto()
  state.shootingTo = gcm.get_game_shootingto()

  --state.body_state = gcm.get_fsm_body_state();
  gcm.set_team_body_state(state.body_state) --hack

  utilMsg.pack_vision_info(state)
  randind = 1
  if math.random()>0.5 then
    randind = 2
  end

  state.currentPositionConfidence = math.max(wcm.get_robot_confidence()-(1-intConf), 0);

  state.teamConfidence = wcm.get_team_my_confidence();

  state.heatLevel = wcm.get_robot_temperature();

  --use a random number to pack labelB to avoid always having top when receiving packages
  utilMsg.pack_labelB_TeamMsg(state, randind)

  return state;

end



function update()
    if Config.game.playerID==6 then return end --Coach does not send anything

    --make sure player 1 is always goalie
    if Config.game.playerID == 1 then
        set_role(ROLE_GOALIE);
        role = ROLE_GOALIE;
    end

    --Update state struct
    state = build_state();

    --Send state
    t = Body.get_time()
    if t-tLastSent > 1/send_fps then
        tLastSent = t
        if Config.dev.comm == 'WebotsComm' then
            msg=serialization.serialize(state)
            Comm.send(msg,#msg)
        else
            msg = utilMsg.convert_state_penn_to_std(state)
            Comm.send(msg)
        end
        state.tReceive = Body.get_time();
        states[playerID] = state;
    end

    -- receive new messages every frame
    recv_msgs_new_comm();

    -- eta and defend distance calculation:
    eta = {};
    ddefend = {};
    roles = {};
    posConf = {};
    t = Body.get_time();

    --Get team ball
    teamball_loc,teamball_score, robot_ballscore = calc_team_ball();

    --figure out how many players are alive
    goalie_alive = 0;
    num_players = 0;
    alive_ids = {};
    for id = 1,5 do
        --make sure we have comms from player and he isn't in penalty
        if states[id] and states[id].penalty == 0 then

            --dont count the goalie in player numbers
            if states[id].role == ROLE_GOALIE then
          --TODO: can be replaced with states[id], or actually just ID ==1
                goalie_alive = 1;
            else
                num_players = num_players + 1;
                alive_ids[num_players] = id;
            end
        end
    end

    teamConf = wcm.get_team_total_confidence();

    --calculate eta to ball and distance to goal (ddefend) for each player
    for id = 1,5 do
	    -- no info from player, ignore him
	    if not states[id] then
        eta[id] = math.huge;
        ddefend[id] = math.huge;
        roles[id] = ROLE_LOST

        --player is alive so we can do calculations for him
	    else
        --grab roles
        roles[id]=states[id].role;

        posConf[id] = states[id].currentPositionConfidence;

        --ETA calculation considering turning, ball uncertainty
        --walkSpeed: seconds needed to walk 1m
        --turnSpeed: seconds needed to turn 360 degrees
        rBall = math.sqrt((teamball_loc[1]-states[id].pose.x)^2 + (teamball_loc[2]-states[id].pose.y)^2);
        eta[id] = rBall/walkSpeed + --Walking time
            math.abs(states[id].attackBearing)/turnSpeed + --Turning
            -- ballLostPenalty * math.max(tBall - tLost, 0);  --Ball uncertainty
            ballLostPenalty * teamball_score;


        --Find distance to our goal
        dgoalPosition = vector.new(wcm.get_goal_defend());
        ddefend[id] = math.sqrt((states[id].pose.x - dgoalPosition[1])^2 +
            (states[id].pose.y - dgoalPosition[2])^2);

        --Add penalties for various roles to prevent rapid switching
        if (states[id].role ~= ROLE_ATTACKER ) then
            eta[id] = eta[id] + nonAttackerPenalty/walkSpeed
        end
        if (states[id].role ~= ROLE_DEFENDER and states[id].role~=ROLE_DEFENDER2) then
            ddefend[id] = ddefend[id] + 0.3;
        end
        if (states[id].fall==1) then
            eta[id] = eta[id] + fallDownPenalty
        end

        --TODO add new penalties

        --too hot Penalty

        --cant see the ball Penalty

        --bad localization confidence penalty
        if (states[id].currentPositionConfidence < 0.5) then
            eta[id] = eta[id] + 2;
        end

        --Bad Team Confidence Penalty
        if (5 - teamConf[id] > 3) then
            eta[id] = eta[id] + 3;
        elseif (5 - teamConf[id] > 1) then
            eta[id] = eta[id] + 1.5;
        end


        --Store this for later
        if id==playerID then wcm.set_team_my_eta(eta[id]) end

        --Ignore goalie, reserver, penalized player, confused player
        if (states[id].penalty > 0) or
          (t - states[id].tReceive > msgTimeout) or
          (states[id].role == ROLE_LOST) or
          (states[id].role == ROLE_GOALIE) then

            eta[id] = math.huge;
            ddefend[id] = math.huge;

        end --endif

	    end --endif
    end --endfor

    --For behavior testing
    force_defender = Config.team.force_defender or 0;
    force_attacker = Config.team.force_attacker or 0;
    if force_defender == 1 then
        set_role(ROLE_DEFENDER);
    end
    if force_attacker == 1 then
        set_role(ROLE_ATTACKER);
    end

    --Now that we know how many players are alive and have eta and ddefend, we can decide how to allocate roles
    --
    --  goalie_alive | num_players |                  roles
    --        1            0         GOALIE - we have a problem if this happens....
    --        1            1         GOALIE,ATTACKER
    --        1            2         GOALIE,ATTACKER,DEFENDER
    --        1            3         GOALIE,ATTACKER,DEFENDER,SUPPORTER
    --        1            4         GOALIE,ATTACKER,DEFENDER,SUPPORTER,DEFENDER2
    --        0            1         ATTACKER
    --        0            2         ATTACKER,DEFENDER
    --        0            3         ATTACKER,DEFENDER,DEFENDER2
    --        0            4         ATTACKER,DEFENDER,DEFENDER2,SUPPORTER


    --dynamic role switch only if we are playing, not forcing role, and not goalie, lost, or penalized
    if gcm.get_game_state()==3 and force_defender == 0 and force_attacker == 0 and
      role~=ROLE_GOALIE and states[playerID].penalty == 0 then

        ETApos = {};
        newETA = util.SortTable(eta);
        for i=1,#newETA do
            id = newETA[i][1];
            pos = i;
            ETApos[id] = pos;
        end

        DDefpos = {};
        newDDef = util.SortTable(ddefend);
        for i=1,#newDDef do
            id = newDDef[i][1];
            pos = i;
            DDefpos[id] = pos;
        end

        --print("ETApos", ETApos[playerID])
        --print("DDefpos",DDefpos[playerID])

        --useful info to know
        myETApos = ETApos[playerID];
        myDDefpos = DDefpos[playerID];
        attackerID = newETA[1][1];
        attackerDDefpos = DDefpos[attackerID];

        --Always become the attacker if
        --we are close, see the ball, and we are not turned far from the goal
        ball = wcm.get_ball();
        rBall = math.sqrt(ball.x^2 + ball.y^2);
        robotToBallAngle = util.mod_angle(math.atan2(ball.y, ball.x) + pose.a);
        -- if rBall < attackerBallThresh and wcm.get_robot_use_team_ball() == 0 and
        -- math.abs(robotToBallAngle) < 90*math.pi/180 then
        --     set_role(ROLE_ATTACKER);
        --     -- log.debug("I'm Attacking!")

        -- --if we are the closest eta or the only one, then we become attacker
        -- elseif myETApos == 1 or num_players == 1 then
        --     set_role(ROLE_ATTACKER);
            -- log.debug("I'm Attacking!")

        --if we are the closest eta or the only one, then we become attacker
        if myETApos == 1 or num_players == 1 then
            set_role(ROLE_ATTACKER);
            -- log.debug("I'm Attacking!")

        --become the attacker if
        --we are close, see the ball, and we are not turned far from the goal
        elseif rBall < attackerBallThresh and wcm.get_robot_use_team_ball() == 0 and
          math.abs(robotToBallAngle) < 90*math.pi/180 then
          set_role(ROLE_ATTACKER);
          -- log.debug("I'm Attacking!")

        --if there are only 2 players or we are closest to goal, we are automatically defender
        --if attacker is also closest to goal and we are second closest, then we are defender
        elseif myDDefpos == 1 or num_players == 2 or (myDDefpos == 2 and attackerDDefpos == 1) then
            set_role(ROLE_DEFENDER);
            -- log.debug("I'm defending");

        --to get here means there are more than 2 players and we are not closest to ball or goal
        --this means we must be either defender2 or supporter
        --If there are exactly 3 players, we can choose based off of goalie status
        elseif num_players == 3 then

            --if goalie is alive we can have supporter
            --print("Goalie Alive?",goalie_alive)
            if goalie_alive then
                set_role(ROLE_SUPPORTER);
                -- log.debug("I'm supporting");
            --if goalie is dead then we should have an extra defender
            else
                set_role(ROLE_DEFENDER2);
                -- log.debug("I'm defending 2");
            end

        --To get here all four players are alive and we are not attacker or defender
        --so we are either defender2 or supporter
        elseif num_players == 4 then
          --We know we will not be pos 1 for EATA or DDefend
          --If we are close to the ball or far from the goal, we can be support
          --For everything else we will just be 2nd defender
          if myETApos == 2 or myDDefpos == num_players then
            set_role(ROLE_SUPPORTER);
          else
            set_role(ROLE_DEFENDER2);
            -- log.debug("I'm defending 2");
          end

        else --we should never get here, but just in case
            set_role(ROLE_LOST);
            -- log.warn("I'm confused :(");
        end


        --Switch roles between left and right defender
        if role==ROLE_DEFENDER or role == ROLE_DEFENDER2 then
            for id = 1,5 do

                --Are there any other defenders?
                if id ~= playerID and
                  (roles[id]==ROLE_DEFENDER or roles[id]==ROLE_DEFENDER2) then

                    --Check if he is on my right side (Def on right, Def2 on left)
                    goalDefend =  wcm.get_goal_defend();
                    if state.pose.y * goalDefend[1] < states[id].pose.y * goalDefend[1] then
                        set_role(ROLE_DEFENDER);
                    else
                        set_role(ROLE_DEFENDER2);
                    end

                end --endif
            end --endfor
        end --endif defender switch

    --We assign role based on player ID during initial and ready state
    elseif gcm.get_game_state()<=2 and force_defender == 0 and force_attacker == 0 and
      role~=ROLE_GOALIE and states[playerID].penalty == 0 then

        for i=1,#alive_ids do
            if alive_ids[i] == playerID then RolePos = i end
        end

        --this ensures even if a player or two is missing, we will always fill in roles in this order
        if RolePos == 1 then
            set_role(ROLE_ATTACKER);
        elseif RolePos == 2 then
            set_role(ROLE_DEFENDER);
        elseif RolePos == 3 then
            set_role(ROLE_SUPPORTER);
        else
            set_role(ROLE_DEFENDER2);
        end

    end --endif playing state vs ready state

    update_shm();
    update_teamdata(goalie_alive,teamball_score,teamball_loc);
    update_local_player_confidence();
    update_team_player_confidence();
    confid = wcm.get_team_total_confidence();
    for i=1,#confid do
      --print("CONFID ", i ,confid[i]);
    end

    update_foul();
    update_obstacle();
    if(Config.platform.name ~= 'WebotsNao') then
      update_heat();
    end

      CD_Testing();

    --Don't need to use these anymore
    --check_confused();
    --fix_flip();

end --end update function


function update_teamdata(goalie_alive,ball_score,ball_loc)
    attacker_eta = math.huge;
    defender_eta = math.huge;
    defender2_eta = math.huge;
    supporter_eta = math.huge;
    goalie_alive = 0;

    attacker_pose = {0,0,0};
    defender_pose = {0,0,0};
    defender2_pose = {0,0,0};
    supporter_pose = {0,0,0};
    goalie_pose = {0,0,0};

    --Update teammates pose information
    for id = 1,5 do

      if states[id] and states[id].tReceive and
        (t - states[id].tReceive < msgTimeout) then

        if states[id].role==ROLE_GOALIE then
            goalie_pose = {states[id].pose.x,states[id].pose.y,states[id].pose.a};
            --goalie_ball = util.pose_global({states[id].ball.x,states[id].ball.y,0},	  goalie_pose);
            --goalie_ball[3] = states[id].ball.t_seen
            goalie_walkTo = states[id].walkingTo;
        elseif states[id].role==ROLE_ATTACKER then
            attacker_pose = {states[id].pose.x,states[id].pose.y,states[id].pose.a};
            attacker_eta = eta[id];
            attacker_walkTo = states[id].walkingTo;
        elseif states[id].role==ROLE_DEFENDER then
            defender_pose = {states[id].pose.x,states[id].pose.y,states[id].pose.a};
            defender_eta = eta[id];
            defender_walkTo = states[id].walkingTo;
        elseif states[id].role==ROLE_SUPPORTER then
            supporter_eta = eta[id];
            supporter_pose = {states[id].pose.x,states[id].pose.y,states[id].pose.a};
            supporter_walkTo = states[id].walkingTo;
        else
            defender2_pose = {states[id].pose.x,states[id].pose.y,states[id].pose.a};
            defender2_eta = eta[id];
            defender2_walkTo = states[id].walkingTo;
        end
      end
    end

    wcm.set_robot_team_ball(ball_loc);
    wcm.set_robot_team_ball_score(ball_score);

    wcm.set_team_attacker_eta(attacker_eta);
    wcm.set_team_defender_eta(defender_eta);
    wcm.set_team_supporter_eta(supporter_eta);
    wcm.set_team_defender2_eta(defender2_eta);

    wcm.set_team_goalie_alive(goalie_alive);

    wcm.set_team_attacker_pose(attacker_pose);
    wcm.set_team_defender_pose(defender_pose);
    wcm.set_team_goalie_pose(goalie_pose);
    wcm.set_team_supporter_pose(supporter_pose);
    wcm.set_team_defender2_pose(defender2_pose);

    wcm.set_team_attacker_walkTo(attacker_walkTo);
    wcm.set_team_defender_walkTo(defender_walkTo);
    wcm.set_team_goalie_walkTo(goalie_walkTo);
    wcm.set_team_supporter_walkTo(supporter_walkTo);
    wcm.set_team_defender2_walkTo(defender2_walkTo);

    wcm.set_team_players_alive(num_players)
    wcm.set_team_pos_confidence(posConf)
end


--calculate the team ball
--@return averaged ball location {x,y,a}, averaged score
--  score is 0 if nobody has seen it
--  score is 0-1 if one player has seen it
--  score is n+avg_score if n players have seen it
function calc_team_ball()

    local scoreBall = vector.zeros(5);
    local etaScoreBall = vector.zeros(5);
    local numBalls = 0;
    local ballID = {};
    local ball_global = vector.zeros(5);

    --loop through all team members
    for id = 1,5 do

        --check to see if we have a message from this player that isn't too old
        if states[id] and states[id].tReceive and (t - states[id].tReceive < msgTimeout) then

            --grab current player state we are considering
            cur_state = states[id]

            --find their position and ball location
            posexya = vector.new({cur_state.pose.x, cur_state.pose.y, cur_state.pose.a});
            ball_global[id] = util.pose_global({cur_state.ball.x,cur_state.ball.y,0},posexya);

            --give their ball a confidence rating based on:
            --  ball probability, ball distance, time seen, location accuracy
            --NOTE: In future this should be calculated by individual players
            --  based on their own ball detection and sent to teammates
            rBall2 = cur_state.ball.x^2 + cur_state.ball.y^2;
            tBall = cur_state.ball.t_seen
            pBall = cur_state.ball.p;
            locConf = cur_state.currentPositionConfidence;
            scoreBall[id] = pBall * locConf * math.exp(-rBall2/12.0) * math.max(0, 1.0 - tBall);

            if (wcm.get_robot_use_team_ball() == 1) then
              etaScoreBall[id] = locConf * math.exp(-rBall2/12.0) * math.max(0, 1.0 - tBall);
            else
              etaScoreBall[id] = math.max(pBall, 0.1) * locConf * math.exp(-rBall2/12.0) * math.max(0, 1.0 - tBall);
            end


            --For debugging
            --print("Ball Score: ", id," ", scoreBall[id]);
            --print("rBall",rBall2)
            --print("tBall",tBall)
            --print("pBall",pBall)
            --print("locConf",locConf)
            --print("ETA ball score: ", id," ", etaScoreBall[id])

            --count how many potential sightings we have and who saw them
            if scoreBall[id] > 0 then
                numBalls = numBalls + 1;
                ballID[numBalls] = id;
            end
        end
    end

    --Now that we have all scores, we need to decide what to do with them
    --If nobody has seen the ball then there isn't much we can do
    if numBalls == 0 then
        ball_loc = {0,0,0};
        ball_score = 0;

    --If only one person has seen the ball then just trust them
    elseif numBalls == 1 then
        id = ballID[1];
        ball_loc = ball_global[id];
        ball_score = scoreBall[id];

    --Multiple people have seen the ball so we need to figure out if they are the same ball or not
    else
        dist_thresh = 0.2;
        sees_teamball = vector.zeros(5);

        --check if any of the balls seen are actually the same
        --NOTE: This assumes that any two balls that are close to each other are automatically the team ball. This does not account for two pairs of robots seeing different balls, since this would be very rare (I think..)
        for i=1,numBalls-1 do
            for j = i+1,numBalls do
                id1 = ballID[i];
                id2 = ballID[j]
                ball1 = ball_global[id1];
                ball2 = ball_global[id2];
                dist = math.sqrt((ball1[1]-ball2[1])^2 + (ball1[2] - ball2[2])^2);
                if dist < dist_thresh then
                    sees_teamball[id1] = 1;
                    sees_teamball[id2] = 1;
                end
            end
        end

        --Now count up how many people agree on team ball and find location and score
        --Location is an average of all ball positions and score is average score plus how many players have seen it
        num_teamball = 0;
        ball_score = 0;
        ball_loc = {0,0,0};
        for i = 1,5 do
            if sees_teamball[i] == 1 then
                num_teamball = num_teamball + 1;
                ball_score = ball_score + scoreBall[i];
                ball_loc[1] = ball_loc[1] + ball_global[i][1];
                ball_loc[2] = ball_loc[2] + ball_global[i][2];
            end
        end

        --If we are actually seeing the teamball, then average the score and location
        if num_teamball > 0 then
            ball_score = ball_score/num_teamball + num_teamball;
            ball_loc = {ball_loc[1]/num_teamball, ball_loc[2]/num_teamball,0};

        --If not, we are seeing different balls, so just choose the one with the highest individual score
        else
            for i = 1,5 do
                if scoreBall[i] > ball_score then
                    ball_score = scoreBall[i];
                    ball_loc[1] = ball_global[i][1];
                    ball_loc[2] = ball_global[i][2];
                end
            end
        end
    end

    return ball_loc,ball_score, etaScoreBall;
end


function exit() end
function get_role()   return role; end
function get_player_id()    return playerID; end
function update_shm() gcm.set_team_role(role);end

function set_role(r)
    if role ~= r then
        role = r;
        Body.set_indicator_role(role);
    end

    if role == nil then
        role = ROLE_DEFENDER2; -- just in case, we had role become nil before and crash stuff
    end
    update_shm();
end

--NSL role can be set arbitarily, so use config value
--set_role(Config.game.role or 1);

--Dont need to use any flipping or confused checks anymore

--[[confused_threshold_x= Config.team.confused_threshold_x or 3.0;
confused_threshold_y= Config.team.confused_threshold_y or 3.0;
flip_threshold_x= Config.team.flip_threshold_x or 1.0;
flip_threshold_y= Config.team.flip_threshold_y or 1.5;
flip_threshold_t= Config.team.flip_threshold_t or 0.5;
flip_check_t = Config.team_flip_check_t or 3.0;
flip_threshold_hard_x= Config.team.flip_threshold_hard_x or 2.0;]]--

--[[function check_confused()

  if wcm.get_team_goalie_alive()==0 then  --Goalie's dead, we're doomed. Kick randomly
    wcm.set_robot_is_confused(0);
    return;
  end
   --Goalie or reserve players never get confused
  if role==ROLE_GOALIE or role > ROLE_DEFENDER2  then
    wcm.set_robot_is_confused(0);
    return;
  end

  pose = wcm.get_pose();
  t = Body.get_time();
  is_confused = wcm.get_robot_is_confused();

  if is_confused>0 then  --Currently confused
    if gcm.get_game_state() ~= 3     --If game state is not gamePlaying
       or gcm.in_penalty() then     --Or the robot is penalized
      wcm.set_robot_is_confused(0); --Robot gets out of confused state!
    end
  else     --Should we turn confused?
    if wcm.get_robot_is_fall_down()>0
       and math.abs(pose.x)<confused_threshold_x
       and math.abs(pose.y)<confused_threshold_y
       and gcm.get_game_state() == 3 then --Only get confused during playing
      wcm.set_robot_is_confused(1);
      wcm.set_robot_t_confused(t);
    end
  end

end


--]]

--WE CAN ADD FOUL STUFF TO THIS !!!!

--[[
function fix_flip()
  local pose = wcm.get_pose();
  local ball = wcm.get_ball();
  local ball_global = util.pose_global({ball.x,ball.y,0},{pose.x,pose.y,pose.a});
  local t = Body.get_time();
  local foul_threshold_t = 10;


  --TODO: Can we trust FAR bal observations?

  --Even the robot thinks he's not flipped, fix flipping if it's too obvious
  if t-ball.t<flip_threshold_t  and goalie_ball[3]<flip_threshold_t then --Both robot seeing the ball
   if (math.abs(ball_global[1])>flip_threshold_hard_x) and
      (math.abs(goalie_ball[1])>flip_threshold_hard_x) and      --Check X position
      ball_global[1]*goalie_ball[1]<0 then
      wcm.set_robot_flipped(1)
	  print('flip1');
	  print(debug.traceback());
    end
  else
    return --cannot fix flip if both robot are not seeing the ball
  end

  if wcm.get_robot_is_confused()==0 then return; end
  local t_confused = wcm.get_robot_t_confused();
  if t-t_confused < flip_check_t then return; end   --Give the robot some time to localize

  --Both I and goalie should see the ball
  if (math.abs(ball_global[1])>flip_threshold_x) and
    (math.abs(goalie_ball[1])>flip_threshold_x) then      --Check X position
    if ball_global[1]*goalie_ball[1]<0 then wcm.set_robot_flipped(1)
		print('flip2');
		print(debug.traceback());
	 end

   --Now we are sure about our position
   wcm.set_robot_is_confused(0);
  elseif (math.abs(ball_global[2])>flip_threshold_y) and
        (math.abs(goalie_ball[2])>flip_threshold_y) then      --Check Y position
    if ball_global[2]*goalie_ball[2]<0 then wcm.set_robot_flipped(1)
		print('flip3');
		print(debug.traceback());
    end
   --Now we are sure about our position
   wcm.set_robot_is_confused(0);
  end

  --ADD SOME GOALKICK AND CORNER RELATED STUFF
  --TODO Zaini, if I see a ball in a location opposite to the current one, I dont need GK to see ball

  --WAIT WHY DONT I JUST PUT THIS IN PARTICLE FILTER?????
  --like not just flip? I'm talking relocalize everything, this however requires decent ball distances. TODO Ask Ryan.
  -- till then, just use it for flips

  -- NOTE DO WE TRUST THE REFEREES???????? Use ball.t or ball.locked_on
  -- See it for a full second
  -- Must have been in foul for at least 10 seconds.

  foulTime = gcm.get_game_time_secondary();
  if(t-ball.t<flip_threshold_t and wcm.get_kick_freeKick() ~=0 and foulTime<30-foul_threshold_t and foulTime > 3 ) then
    if(wcm.get_obstacle_foulType() == 1) then
      if(ball_global[1] > 0) then
        wcm.set_robot_flipped(1)
  	    print('flip Foul 1');
  	    print(debug.traceback());
      end
    elseif(wcm.get_obstacle_foulType() == 2) then
      if(ball_global[1] < 0) then
        wcm.set_robot_flipped(1)
  	    print('flip Foul 2');
  	    print(debug.traceback());
      end
    elseif(wcm.get_obstacle_foulType() == 5) then
      if(ball_global[1] < 0) then
        wcm.set_robot_flipped(1)
  	    print('flip Foul 5');
  	    print(debug.traceback());
      end
    elseif(wcm.get_obstacle_foulType() == 6) then
      if(ball_global[1] > 0) then
        wcm.set_robot_flipped(1)
  	    print('flip Foul 6');
  	    print(debug.traceback());
      end
    end
  end


end

--]]


--Update local obstacle information based on other robots' localization info
function update_obstacle()

    local t = Body.get_time();
    local t_timeout = 2.0;
    pose = wcm.get_pose();
    obstacle_count = 0;
    obstacle_x = vector.zeros(10);
    obstacle_y = vector.zeros(10);
    obstacle_dist = vector.zeros(10);
    obstacle_role = vector.zeros(10);
    obstacle_radius = vector.zeros(10);
    foulType = wcm.get_obstacle_foulType();

    --loop through own team and opponenets
    for i=1, 10 do

        --check to make sure the data we have is valid
        if t_poses[i]~=0 and t-t_poses[i]<t_timeout and player_roles[i]< ROLE_LOST  then

            obstacle_count = obstacle_count+1;

            --get location of obstacle relative to my current position
            local obstacle_local = util.pose_relative({poses[i].x,poses[i].y,0},{pose.x,pose.y,pose.a});

            --use relative positoin to find distance and xy coords
            dist = math.sqrt(obstacle_local[1]^2+obstacle_local[2]^2);
            obstacle_x[obstacle_count]=obstacle_local[1];
            obstacle_y[obstacle_count]=obstacle_local[2];
            obstacle_dist[obstacle_count]=dist;
            obstacle_radius[obstacle_count] = 0.3; --ROBOT OBSTACLE RADIUS IS 30cm

            --assig obstacle role based on team
            if i<6 then --Same team
                obstacle_role[obstacle_count] = player_roles[i]; --0,1,2,3,4
            else --Opponent team
                obstacle_role[obstacle_count] = player_roles[i]+5; --5,6,7,8,9
            end
        end
    end


-- Foul Types
--0 = No Foul
--1 = Goalkick for us
--2 = Goalkick for them
--3 = Freekick for us
--4 = Freekick for them
--5 = Corner for us
--6 = Corner for them
--7 = Kick-in for us
--8 = Kick-in for them

  if(wcm.get_kick_freeKick() == 2) then
    obstacle_count = 1 + obstacle_count;
    obstacle_x[obstacle_count] = foulLoc[1];
    obstacle_y[obstacle_count] = foulLoc[2];
    obstacle_dist[obstacle_count] = math.sqrt((foulLoc[1]-pose.x)^2+(foulLoc[2]-pose.y)^2);
    obstacle_role[obstacle_count] = 10;
    obstacle_radius[obstacle_count] = foulRad;
    if(wcm.get_obstacle_foulConf() == 0) then
      if(foulType == 2) then --Their goalKick
        obstacle_count = 1 + obstacle_count;
        obstacle_x[obstacle_count] = 3.2;
        obstacle_y[obstacle_count] = 1.1;
        obstacle_dist[obstacle_count] = math.sqrt((3.2-pose.x)^2+(1.1-pose.y)^2);
        obstacle_role[obstacle_count] = 11;
        obstacle_radius[obstacle_count] = 0.8;
        obstacle_count = 1 + obstacle_count;
        obstacle_x[obstacle_count] = 3.2;
        obstacle_y[obstacle_count] = -1.1;
        obstacle_dist[obstacle_count] = math.sqrt((3.2-pose.x)^2+(-1.1-pose.y)^2);
        obstacle_role[obstacle_count] = 12;
        obstacle_radius[obstacle_count] = 0.8;
      elseif (foulType == 6) then --Their CornerKick
        obstacle_count = 1 + obstacle_count;
        obstacle_x[obstacle_count] = -4.5;
        obstacle_y[obstacle_count] = 3;
        obstacle_dist[obstacle_count] = math.sqrt((-4.5-pose.x)^2+(3-pose.y)^2);
        obstacle_role[obstacle_count] = 11;
        obstacle_radius[obstacle_count] = 0.8;
        obstacle_count = 1 + obstacle_count;
        obstacle_x[obstacle_count] = -4.5;
        obstacle_y[obstacle_count] = -3;
        obstacle_dist[obstacle_count] = math.sqrt((-4.5-pose.x)^2+(-3-pose.y)^2);
        obstacle_role[obstacle_count] = 12;
        obstacle_radius[obstacle_count] = 0.8;
      end
    end
  end


		--print("num Obstacles: ", obstacle_count);
    --NEED TO HANDLE GK, Maybe adjust goalie. I dont want the GK to avoid the ball, just dont give the GK any obstacles??

    their_kickoff_time = wcm.get_obstacle_kickOffTime()

    if(t - their_kickoff_time <= 10) then
      obstacle_count = 1 + obstacle_count;
      obstacle_x[obstacle_count] = 0;
      obstacle_y[obstacle_count] = 0;
      obstacle_dist[obstacle_count] = math.sqrt((pose.x)^2+(pose.y)^2);
      obstacle_role[obstacle_count] = 13; -- center cirlce
      obstacle_radius[obstacle_count] = 0.85;
    end

    --goal post obstacles (for all non attacker or GK)







    --Illegal defender obstacle






    --update shm with this info
    wcm.set_obstacle_num(obstacle_count);
    wcm.set_obstacle_x(obstacle_x);
    wcm.set_obstacle_y(obstacle_y);
    wcm.set_obstacle_dist(obstacle_dist);
    wcm.set_obstacle_role(obstacle_role);
    wcm.set_obstacle_radius(obstacle_radius);

		obs=wcm.get_obstacle_x();
		--for i=1, #obs do
			--print("obstacle ", i, " ", obs[i]);
		--end



--:TODO
-- This may be a problem, are we passing ourself as an obstacle??????? like to ourself.



  --log.warn(" ", get_player_id() ," ", Body.get_time(), " ", foulType, " ", foulLoc[1], " ", foulLoc[2]);


end



function update_foul()
  setPlay=gcm.get_game_setPlay();
  kickoffTeam=gcm.get_game_kickoff();
  ball = wcm.get_ball()
  time = Body.get_time();
  pose = wcm.get_pose();

  --not used for webots testing since both values are initialized to 0
  if(Config.platform.name ~= 'WebotsNao') then
    if(setPlay == 1 and kickoffTeam == 1 ) then
      wcm.set_obstacle_foulType(1);
      wcm.set_kick_freeKick(1);
    elseif(setPlay == 1 and kickoffTeam ~= 1 ) then
      wcm.set_obstacle_foulType(2);
      wcm.set_kick_freeKick(2);
    elseif(setPlay == 2 and kickoffTeam == 1 ) then
      wcm.set_obstacle_foulType(3);
      wcm.set_kick_freeKick(1);
    elseif(setPlay == 2 and kickoffTeam ~= 1 ) then
      wcm.set_obstacle_foulType(4);
      wcm.set_kick_freeKick(2);
    elseif(setPlay == 3 and kickoffTeam == 1 ) then
      wcm.set_obstacle_foulType(5);
      wcm.set_kick_freeKick(1);
    elseif(setPlay == 3 and kickoffTeam ~= 1 ) then
      wcm.set_obstacle_foulType(6);
      wcm.set_kick_freeKick(2);
    elseif(setPlay == 4 and kickoffTeam == 1 ) then
      wcm.set_obstacle_foulType(7);
      wcm.set_kick_freeKick(1);
    elseif(setPlay == 4 and kickoffTeam ~= 1 ) then
      wcm.set_obstacle_foulType(8);
      wcm.set_kick_freeKick(2);
    elseif(setPlay == 0) then
      wcm.set_obstacle_foulType(0);
      wcm.set_kick_freeKick(0);
    end
  end

  foulType = wcm.get_obstacle_foulType();
  foulLoc = World.pose_global({ball.x, ball.y, 0}, {pose.x, pose.y, pose.a});
  if((time - ball.t > 3) and wcm.get_robot_use_team_ball() == 0) then
    foulRad = 1;
    wcm.set_obstacle_foulConf(0);
  else
    foulRad = 0.8;
    wcm.set_obstacle_foulConf(1);
  end
end

function update_heat()

  temperatures = Body.get_sensor_temperature();

  --3-12 is left
  --13-22 is right
  tempLeft, tempRight = 0, 0;

  for i = 7,12 do
    tempLeft = tempLeft + temperatures[i]^2;
  end
  for i = 13,18 do
      tempRight = tempRight + temperatures[i]^2;
  end
  tempLeft = math.sqrt(tempLeft/6);
  tempRight = math.sqrt(tempRight/6);

  tempRating = tempLeft + tempRight;
  if tempLeft > tempRight then tempSide = 0 else tempSide =1; end

  --rint(tempRating);

  wcm.set_robot_temperature(tempRating);
  wcm.set_robot_temperatureSide(tempSide);

end

startTime = 0;
tS = vector.zeros(100)
i_cd = 1

function CD_Testing()
  test_cd = wcm.get_robot_cd()
  t = Body.get_time();
  numPlayers = wcm.get_team_players_alive()
  extDis = wcm.get_team_total_confidence();
  intDis = wcm.get_team_pos_confidence();
  if (numPlayers) and (extDis) and (intDis) then
    if(test_cd == 0) then
      startTime = -1
    elseif(test_cd == 1 and startTime == -1) then
      startTime = t;
    end
    if test_cd == 1 then
      tS[i_cd] = {playerID, intDis[playerID], (intDis[playerID] + (extDis[playerID] - (5- numPlayers))/numPlayers)/2, (extDis[playerID] - (5- numPlayers))/numPlayers}
      i_cd = i_cd +1;
    end

    if(t - startTime > 10 ) and (test_cd == 1)  then
      i_cd = 1
      wcm.set_robot_cd(0)
      print("CD DONE !!!!!!!")
      util.printtable(tS)
      for i = 1,5 do
        reset_local_player_confidence(i);
      end
    end
  end

end
