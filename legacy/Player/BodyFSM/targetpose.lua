module(..., package.seeall);
require('Body')
require('walk')
require('util')
require('vector')
require('Config')
require('wcm')
require('gcm')

ROLE_GOALIE = 0;
ROLE_ATTACKER = 1;
ROLE_DEFENDER = 2;
ROLE_SUPPORTER = 3;
ROLE_DEFENDER2 = 4;

--This file calculates the TARGET global position

rDist1 = Config.fsm.bodyPosition.rDist1;
rDist2 = Config.fsm.bodyPosition.rDist2;
rOrbit = Config.fsm.bodyPosition.rOrbit;
daPostMargin = Config.fsm.daPostMargin or 15*math.pi/180;

yFieldOffset = Config.team.yFieldOffset;

function getRoleSpecificHomePose()
  local role = gcm.get_team_role();--role starts with 0
  local is_confused = wcm.get_robot_is_confused();
  local kickDir = wcm.get_kick_dir();
  local homepose, homepose2
  if Config.fsm.playMode == 1 then
    homepose = getDirectAttackerHomePose()
  elseif (role == ROLE_DEFENDER) then
    homepose = getDefenderHomePose()
  elseif (role == ROLE_DEFENDER2) then
    homepose = getDefenderLeftHomePose()
  elseif (role == ROLE_SUPPORTER) then
    homepose = getSupporterHomePose()
  else --Attacker
    if Config.fsm.playMode ~= 3 or kickDir ~= 1 or is_confused > 0 then
      homepose = getDirectAttackerHomePose()
    else
      homepose, homepose2 = getAttackerHomePose()
    end
  end
    if(inObstacle(homepose)) then
      edgeOfFoul = getEdgeOfFoul(homepose);
      homepose = {edgeOfFoul[1], edgeOfFoul[2], edgeOfFoul[3]};
    end
  if homepose2 then
    gcm.set_team_pose_target(homepose2)
  else
    gcm.set_team_pose_target(homepose)
  end
  return homepose
end

function getEdgeOfFoul(homepose)
  obstacle_role = wcm.get_obstacle_role();
  foulType = wcm.get_obstacle_foulType();
  obstacle_x = wcm.get_obstacle_x();
  obstacle_y = wcm.get_obstacle_y();
  obstacle_radius = wcm.get_obstacle_radius();
  obstacle_num = wcm.get_obstacle_num();

  pose = wcm.get_pose();
  role=gcm.get_team_role();
  --Mainly attacker plans, but for other positions we just try to create a barrior around goals.
  --Supporter foul strategies are in supporter strategies.

  if(wcm.get_kick_freeKick() == 2) then
    if( (wcm.get_obstacle_foulConf() == 1) or (foulType==4) ) then --ball is the foul
      for i = 1, obstacle_num do
        if(obstacle_role[i] == 10) then
          obs1 = i;
        end
      end
      pDist = (math.sqrt((homepose[1] - obstacle_x[obs1])^2 + (homepose[2] - obstacle_y[obs1])^2));
      if(pDist < obstacle_radius[obs1]) then
        foulPos = {obstacle_x[obs1], obstacle_y[obs1]};
        rad= obstacle_radius[obs1];
      end
      goalDist = (math.sqrt((-4.5 - foulPos[1])^2 + (0 - foulPos[2])^2));
      xside= (foulPos[1]+4.5);
      yside= (foulPos[2]);
      angleFoul=math.atan2((0 - foulPos[2]), (-4.5 - foulPos[1]));
      xPos = foulPos[1]-math.abs(math.cos(angleFoul))*rad;
        if(foulPos[2] > 0) then
          sign = 1;
        else
          sign = -1;
        end
      yPos = foulPos[2]+math.sin(angleFoul)*rad;

      angBall=math.atan2(foulPos[2]-pose.y, foulPos[1]-pose.x);

      if(foulType==6) then
        xPos = math.max(xPos, -4.35);
      end
      --[[

      --US OPEN HACKS, CAN BE USED IF WE DONT HAVE A*

      if((pose.x > foulPos[1]) and (pose.y - foulPos[2])^2 < 0.6) then

        if((pose.y > foulPos[2]) and (foulPos[2] + rad) < 3) then -- I'm above the foul
          xPos = foulPos[1];
          yPos = foulPos[2]+rad;
          --print("1");
        elseif((pose.y <= foulPos[2]) and (foulPos[2] - rad) > -3) then-- I'm below the foul
          xPos = foulPos[1];
          yPos = foulPos[2]-rad;
          --print("2");
        else
          xPos = foulPos[1]+2*math.cos(angleFoul)*rad;
          yPos = foulPos[2]-math.sin(angleFoul)*rad*sign;
          --print("3");
        end
        --print("SPECIAL BEHAVIOR");
        --print("HomePose X:", xPos,"Y:", yPos);
      else
        --print("4");
        --print("Normal");
        --print("HomePose X:", xPos,"Y:", yPos);
      end

      --print("x: ", xPos, "y: ", yPos);

      if(role==1 and (foulPos[1]<-1 and (wcm.get_team_players_alive()>=3))  ) then

        angleFoul=math.atan2((homepose[2] - foulPos[2]), (homepose[1] - foulPos[1]));

        return {foulPos[1]+math.cos(angleFoul)*rad, foulPos[2]+math.sin(angleFoul)*rad ,angBall};
      end

      --]]

      --TODO need to handle case where the foul is close to our goal. Too many robots


    return {xPos, yPos, angBall};

    else
      if(foulType==2) then --goal freeKick
        for i = 1, obstacle_num do
          if(obstacle_role[i] == 11) then
            obs1 = i;
          elseif(obstacle_role[i] == 12) then
            obs2 = i;
          elseif(obstacle_role[i] == 10) then
            obs3 = i;
          end
        end
        pDist1 = (math.sqrt((homepose[1] - obstacle_x[obs1])^2 + (homepose[2] - obstacle_y[obs1])^2));
        pDist2 = (math.sqrt((homepose[1] - obstacle_x[obs2])^2 + (homepose[2] - obstacle_y[obs2])^2));
        if(pDist1 < obstacle_radius[obs1]) then
          foulPos = {obstacle_x[obs1], obstacle_y[obs1]};
          rad= obstacle_radius[obs1];
        elseif (pDist2 < obstacle_radius[obs2]) then
          foulPos = {obstacle_x[obs2], obstacle_y[obs2]};
          rad= obstacle_radius[obs2];
        else --ELSE ITS OLD BALL POSITION
          foulPos = {obstacle_x[obs3], obstacle_y[obs3]};
          rad= obstacle_radius[obs3];
        end
        goalDist = (math.sqrt((-4.5 - foulPos[1])^2 + (0 - foulPos[2])^2));
        xside= (foulPos[1]+4.5);
        yside= (foulPos[2]);
        angleFoul=math.atan2((0 - foulPos[2]), (-4.5 - foulPos[1]));
        xPos = foulPos[1]-math.abs(math.cos(angleFoul))*rad;
          if(foulPos[2] > 0) then
            sign = 1;
          else
            sign = -1;
          end
        yPos = foulPos[2]+math.sin(angleFoul)*rad;

        angBall=math.atan2(foulPos[2]-pose.y, foulPos[1]-pose.x);


      elseif (foulType==4) then --foul freeKick
        --Shouldn't be here, placed for continuity but its handled in step above.
      elseif (foulType==6) then --Corner freeKick
        for i = 1, obstacle_num do
          if(obstacle_role[i] == 11) then
            obs1 = i;
          elseif(obstacle_role[i] == 12) then
            obs2 = i;
          elseif(obstacle_role[i] == 10) then
            obs3 = i;
          end
        end
        pDist1 = (math.sqrt((homepose[1] - obstacle_x[obs1])^2 + (homepose[2] - obstacle_y[obs1])^2));
        pDist2 = (math.sqrt((homepose[1] - obstacle_x[obs2])^2 + (homepose[2] - obstacle_y[obs2])^2));
        if(pDist1 < obstacle_radius[obs1]) then
          foulPos = {obstacle_x[obs1], obstacle_y[obs1]};
          rad= obstacle_radius[obs1];
        elseif (pDist2 < obstacle_radius[obs2]) then
          foulPos = {obstacle_x[obs2], obstacle_y[obs2]};
          rad= obstacle_radius[obs2];
        else --ELSE ITS OLD BALL POSITION
          foulPos = {obstacle_x[obs3], obstacle_y[obs3]};
          rad= obstacle_radius[obs3];
        end
        goalDist = (math.sqrt((-4.5 - foulPos[1])^2 + (0 - foulPos[2])^2));
        xside= (foulPos[1]+4.5);
        yside= (foulPos[2]);
        angleFoul=math.atan2((0 - foulPos[2]), (-4.5 - foulPos[1]));
        xPos = -4.35--foulPos[1]-math.abs(math.cos(angleFoul))*rad;
          if(foulPos[2] > 0) then
            sign = 1;
          else
            sign = -1;
          end
        yPos = foulPos[2]+math.sin(angleFoul)*rad;

        angBall=math.atan2(foulPos[2]-pose.y, foulPos[1]-pose.x);





      elseif (foulType==8) then --kickin freeKick
        --for Now do nothing, but maybe we should move to 0.8 away from the edges.
        --For now I'm priotizing ball detection
      end
    end
  end

  --US OPEN HACKS
  --[[
  if(role==2 and foulPos[1]<-3) then
    angleFoul = angleFoul+math.pi/4;
  elseif(role==3 and foulPos[1]<-1) then
    --WE SHOULD NEVER REACH THIS STAGE
    angleFoul = angleFoul-math.pi/2;
  elseif(role==4 and foulPos[1]<-3) then
    angleFoul = angleFoul-math.pi/4;
  end
  --]]

  return {xPos, yPos, angBall};

end

function inObstacle(homepose)
  obstacle_role = wcm.get_obstacle_role();
  obstacle_num = wcm.get_obstacle_num();
  obstacle_x = wcm.get_obstacle_x();
  obstacle_y = wcm.get_obstacle_y();
  obstacle_dist = wcm.get_obstacle_dist();
  obstacle_role = wcm.get_obstacle_role();
  obstacle_radius = wcm.get_obstacle_radius();
  foulType = wcm.get_obstacle_foulType();

  --add non-foul Obstacles. Generalize to stop us from planning paths where other robots are.

  --Yes I know that I'm pennalizing both the ball pos and field locs.
  --This is so that poorly localized robots dont get penalized for fouls.
  --Actually pennalizing poorly localized robots doesnt seem that bad? It might help them relocalize TODO.

  if(wcm.get_kick_freeKick() == 2) then
    for i = 1, obstacle_num do
      if(obstacle_role[i] == 10) then
        obs1 = i;
      end
    end
    if(obstacle_y[obs1] ~= nil) then
      pDist =(math.sqrt((homepose[1] - obstacle_x[obs1])^2 + (homepose[2] - obstacle_y[obs1])^2));
      if(pDist < obstacle_radius[obs1]) then
        return true;
      end
    end
    if(wcm.get_obstacle_foulConf() == 0) then
      if(foulType==2) then --goal freeKick
        for i = 1, obstacle_num do
          if(obstacle_role[i] == 11) then
            obs1 = i;
          elseif(obstacle_role[i] == 12) then
            obs2 = i;
          end
        end
        if(obstacle_y[obs1] ~= nil and obstacle_y[obs2] ~= nil) then
          pDist1 =(math.sqrt((homepose[1] - obstacle_x[obs1])^2 + (homepose[2] - obstacle_y[obs1])^2));
          pDist2 =(math.sqrt((homepose[1] - obstacle_x[obs2])^2 + (homepose[2] - obstacle_y[obs2])^2));
          if(pDist1 < obstacle_radius[obs1] or pDist2 < obstacle_radius[obs2]) then
            return true;
          end
        end
      elseif (foulType==6) then --corner freeKick
        for i = 1, obstacle_num do
          if(obstacle_role[i] == 11) then
            obs1 = i;
          elseif(obstacle_role[i] == 12) then
            obs2 = i;
          end
        end
        if(obstacle_y[obs1] ~= nil and obstacle_y[obs2] ~= nil) then
          pDist1 =(math.sqrt((homepose[1] - obstacle_x[obs1])^2 + (homepose[2] - obstacle_y[obs1])^2));
          pDist2 =(math.sqrt((homepose[1] - obstacle_x[obs2])^2 + (homepose[2] - obstacle_y[obs2])^2));
          if(pDist1 < obstacle_radius[obs1] or pDist2 < obstacle_radius[obs2]) then
            return true;
          end
        end
      elseif (foulType==8) then --kickIn
        if(homepose[2] > 2.2 or homepose[2] < -2.2) then
          return true;
        end
      end
    end
  end
  return false;
end


function getReadyHomePose()
  local role = gcm.get_team_role();--role starts with 0
  local initPosition1 = Config.world.initPosition1[role + 1]
  local initPosition2 = Config.world.initPosition2[role + 1]

  local goal_defend = wcm.get_goal_defend();
  local homepose
  if gcm.get_game_kickoff() == 1 then
    homepose = vector.new({initPosition1[1], initPosition1[2], 0})
  else
    homepose = vector.new({initPosition2[1], initPosition2[2], 0})
  end
  homepose = homepose*util.sign(goal_defend[1]);

  --rotates homepose values by 180 degrees if defending the other goal
  if goal_defend[1] > 0 then homepose[3] = math.pi
  else homepose[3] = 0 end
  gcm.set_team_pose_target(homepose)
  return homepose
end

function getDirectAttackerHomePose()
  ball, pose = wcm.get_ball(), wcm.get_pose()
  aBall = aBall or 0
  ballR = math.sqrt(ball.x^2 + ball.y^2);
  ballxy = vector.new( {ball.x, ball.y, 0} );
  tBall = Body.get_time() - ball.t;
  posexya = vector.new( {pose.x, pose.y, pose.a} );
  ballGlobal = util.pose_global(ballxy, posexya);

  return {ballGlobal[1] - math.cos(aBall)*rDist2, ballGlobal[2] - math.sin(aBall)*rDist2, aBall}
end

function getAttackerHomePose()

  local ball, pose = wcm.get_ball(), wcm.get_pose()
  local ballxy = vector.new( {ball.x, ball.y, 0})
  local posexya = vector.new( {pose.x, pose.y, pose.a})
  local ballGlobal = util.pose_global(ballxy, posexya)
  local aBall = math.atan2(ballGlobal[2] - pose.y, ballGlobal[1] - pose.x);
  local ballR = math.sqrt(ball.x^2 + ball.y^2);

  local postAttack = Config.world.postYellow
  if gcm.get_team_color() == 1 then
    postAttack = Config.world.postCyan
  end

  --calculates angle of goal from the ball
  local LPost, RPost = postAttack[1], postAttack[2]
  local aGoal1 = math.atan2(LPost[2] - ballGlobal[2], LPost[1] - ballGlobal[1])
  local aGoal2 = math.atan2(RPost[2] - ballGlobal[2], RPost[1] - ballGlobal[1])

  local daPost = math.abs(util.mod_angle(aGoal1 - aGoal2))
  local aGoal = aGoal2 + 0.5 * daPost

  local daPost1 = math.max(0, daPost - daPostMargin);
  local kickAngle = wcm.get_kick_angle()

  local angle2Turn, aGoalSelected

  --Left and right boundaries for final angle
  local aGoalL, aGoalR = aGoal + daPost1*0.5 - kickAngle, aGoal - daPost1*0.5 - kickAngle

  --How much we need to turn around the ball?
  local angleL, angleR = util.mod_angle(aGoalL - aBall), util.mod_angle(aGoalR - aBall);

  if angleL < 0 then angle2Turn,aGoalSelected = angleL, aGoalL --Aim to the left boundary
  elseif angleR > 0 then angle2Turn,aGoalSelected = angleR, aGoalR --Aim to the right boundary
  else angle2Turn, aGoalSelected = 0, pose.a end --We can kick straight forward


  --Disable left-right check
  if dapost_check == 0 then aGoalSelected,angle2Turn = aGoal, util.mod_angle(aGoal - aBall) end

  --the final home pose (after circling around the ball)
  rDist = math.min(rDist2 + (rDist1 - rDist2) * math.abs(angle2Turn)/(math.pi/2), ballR)
  local homepose2 =
    {ballGlobal[1] - math.cos(aGoalSelected)*rDist,
    ballGlobal[2] - math.sin(aGoalSelected)*rDist,
    aGoalSelected}

  --Curved approach
  if math.abs(angle2Turn) < math.pi/2 then
    return homepose2 --No need to turn around
  elseif angleL > 0 then --Circle around the ball
    return {ballGlobal[1] + math.cos(-aBall + math.pi/2)*rOrbit,
      ballGlobal[2] - math.sin(-aBall + math.pi/2)*rOrbit, aBall},
      homepose2
  else
    return {ballGlobal[1] + math.cos(-aBall - math.pi/2)*rOrbit,
      ballGlobal[2] - math.sin(-aBall - math.pi/2)*rOrbit, aBall},
      homepose2
  end
end



defender_pos_0 = Config.team.defender_pos_0 or {1.0, 0}; --no goalie
defender_pos_1 = Config.team.defender_pos_1 or {1.5, 0.3}; --1 defender
defender_pos_2 = Config.team.defender_pos_2 or {1.5, 0.5}; --Left defender
defender_pos_3 = Config.team.defender_pos_3 or {1.5, -0.5}; --Right defender

function getDefenderHomePose()
  local ball, pose = wcm.get_ball(), wcm.get_pose()
  local ballxy = vector.new({ball.x, ball.y, 0})
  local posexya = vector.new({pose.x, pose.y, pose.a})
  local ballGlobal = util.pose_global(ballxy, posexya)
  local aBall = math.atan2(ballGlobal[2] - pose.y, ballGlobal[1] - pose.x);
  local ballR = math.sqrt(ball.x^2 + ball.y^2);

  local goal_defend = wcm.get_goal_defend();
  local relBallX = ballGlobal[1] - goal_defend[1];
  local relBallY = ballGlobal[2] - goal_defend[2];
  local RrelBall = math.sqrt(relBallX^2 + relBallY^2) + 0.001;

  --Check attacker position
  local attacker_pose = wcm.get_team_attacker_pose();
  local goalie_alive = wcm.get_team_goalie_alive();

  local attacker_goal_dist = math.sqrt(
    (attacker_pose[1] - goal_defend[1])^2 + (attacker_pose[2] - goal_defend[2])^2)

  local defender_goal_dist = math.sqrt(
    (pose.x - goal_defend[1])^2 + (pose.y - goal_defend[2])^2)

  homePosition = {}

  defending_type = 1;

  support_dist = Config.team.support_dist or 3.0;
  supportPenalty = Config.team.supportPenalty or 0.3;


  --How close is the ball to our goal?
  if RrelBall < support_dist then --Ball close to our goal
    -- is our attacker closer to the goal than me?
    if attacker_goal_dist < defender_goal_dist - supportPenalty then
      --Attacker is closer to our goal
      defending_type = 2; --Go back to side of our field
    else --Defender closer to our goal
      defending_type = 1; --Center defender
    end
  else --Ball is not close to our goal
    if attacker_goal_dist < defender_goal_dist - supportPenalty then
       --Attacker closer to the our goal, we can move forward and do the support

      --Do we have a supporter player around? then just go back and play defense
      supporter_eta = wcm.get_team_supporter_eta();
			first_defender_eta = wcm.get_team_defender_eta();
			second_defender_eta = wcm.get_team_defender2_eta();
      lowest_defender_eta = math.min(first_defender_eta, second_defender_eta);
      if (supporter_eta < lowest_defender_eta) then --We have a supporter around
        defending_type = 2; --Go back
      else
        defending_type = 3; --Supporter
      end
    else
      --Stay in defending position
      --TODO: we can still go support
      defending_type = 1;
--      defending_type = 3;
    end
  end

  --Center defender
  if defending_type == 1 then
    if goalie_alive > 0 then
      distGoal, sideGoal = defender_pos_1[1], defender_pos_1[2];
      --TODO: multiple defender handling
    else
      --NO goalie
      distGoal, sideGoal = defender_pos_0[1], defender_pos_0[2];
    end

    homePosition[1] = goal_defend[1] + distGoal*relBallX/RrelBall;
    homePosition[2] = goal_defend[2] + distGoal*relBallY/RrelBall +
      util.sign(goal_defend[1])*sideGoal;
    homePosition[3] = math.atan2(relBallY, relBallX);
    --print("Defending type: 1")

  --Side defender, avoiding attacker
  elseif defending_type == 2 then
    homePosition[1] = goal_defend[1]/2;

    if math.abs(attacker_pose[2]) < 0.5 then
      homePosition[2] = util.sign(pose.y) * 1.0;
    else
      homePosition[2] = -util.sign(attacker_pose[2]) * 1.0;
    end

    homePosition[3] = util.mod_angle(math.atan2(relBallY, relBallX));
    -- print("angle calcs", math.atan2(relBallY, relBallX), util.mod_angle(math.atan2(ball.y, ball.x) + pose.a))
    --print("Defending type: 2")
  elseif defending_type == 3 then
    --print("Defending type: 3")
    -- calculate targetpose for a supporter since defender is closer to the ball than supporter
    return getSupporterHomePose()
  end

  -- if the robot is one of the defenders and the ball is in the opponents' half, change x-position based on where the ball is.
  --[[if (defending_type ~= 3) then
		attackerDesiredPos = wcm.get_team_attacker_walkTo();
		if math.abs(0.5 * attackerDesiredPos[1] - homePosition[1]) > 1 and attackerDesiredPos[1] < 0 then
   		homePosition[1] = 0.5 * attackerDesiredPos[1];
  	end
	end]]--

  -- print("defender pose: ", pose.x, pose.y, pose.a*180/math.pi)
  -- print("role", gcm.get_team_role())
  -- print("defending type ", defending_type)
  -- print("defender pose", pose.x, pose.y, pose.a)
  -- print("defender homePose: ", homePosition[1], homePosition[2], homePosition[3]*180/math.pi)

  return homePosition;
end


--Position for 2nd defender (Nao only)
function getDefenderLeftHomePose()
  local ball, pose = wcm.get_ball(), wcm.get_pose()
  local ballxy = vector.new({ball.x, ball.y, 0})
  local posexya = vector.new({pose.x, pose.y, pose.a})
  local ballGlobal = util.pose_global(ballxy, posexya)
  local aBall = math.atan2(ballGlobal[2] - pose.y, ballGlobal[1] - pose.x);
  local ballR = math.sqrt(ball.x^2 + ball.y^2);

  goal_defend = wcm.get_goal_defend();
  relBallX = ballGlobal[1] - goal_defend[1];
  relBallY = ballGlobal[2] - goal_defend[2];
  RrelBall = math.sqrt(relBallX^2 + relBallY^2) + 0.001;

  homePosition = {};

  --Center defender
  distGoal, sideGoal = defender_pos_2[1], -defender_pos_2[2];

  homePosition[1] = goal_defend[1] + distGoal * relBallX/RrelBall;
  homePosition[2] = goal_defend[2] + distGoal * relBallY/RrelBall
  + util.sign(goal_defend[1])*sideGoal;
  homePosition[3] = math.atan2(relBallY, relBallX);

  -- print("defender2 pose: ", pose.x, pose.y, pose.a*180/math.pi)
  -- print("defender2 homePose: ", homePosition[1], homePosition[2], homePosition[3]*180/math.pi)

  return homePosition;
end


function getZainiDefenderHomePose()

--[[

  first determine the line from the ball to the goal

  y=mx+c where m=y1-y2/x1-x2  and c = 4.5*m
  Dont really need this? cant I just angle? no not for how Xiang wants this.



  next determine if I'm front or if I'm back (this should be done using the homepos and not actual position?)
  Lastly, determine where to stand on the radius

  x position should be determined based on a ratio, so lets just say at a fixed y position

  larger deviation above, smaller deviation below

  --]]


  local ball, pose = wcm.get_ball(), wcm.get_pose()
  local ballxy = vector.new({ball.x, ball.y, 0})
  local posexya = vector.new({pose.x, pose.y, pose.a})
  local ballGlobal = util.pose_global(ballxy, posexya)
  local aBall = math.atan2(ballGlobal[2] - pose.y, ballGlobal[1] - pose.x);
  local ballR = math.sqrt(ball.x^2 + ball.y^2);

  --TODO: check if the other defender is alive, could be based on TeamSPL role calculations.
  otherDef = wcm.get_team_defender2_pose();
  local ballR2 = math.sqrt((ballGlobal[1] - otherDef[1])^2 + (ballGlobal[2]-otherDef[2])^2);

  goal_defend = wcm.get_goal_defend();
  relBallX = ballGlobal[1] - goal_defend[1];
  relBallY = ballGlobal[2] - goal_defend[2];
  RrelBall = math.sqrt(relBallX^2 + relBallY^2);

  prevPosFB = wcm.get_team_isFrontDef();

  --posFB 1 for front def, 0 for back, changed so that there is an impact on previous assignments in the allocation
  if (ballR - 0.2*prevPosFB < ballR2 - (0.2 - 0.2*prevPosFB)) then
    posFB = 1;
    wcm.set_team_isFrontDef(1);
  else
    posFB = 0;
    wcm.set_team_isFrontDef(0);
  end

  if(prevPosFB ~= posFB) then
    if(posFB > 0) then
      print("D1 JUST CHANGED TO FRONT");
    else
      print("D1 JUST CHANGED TO BACK");
    end
  end

  --POLAR COORDINATES, DOESNT WORK
  --[[
  aGoal = math.atan2(relBallX, relBallY);

  if(posFB == 1) then
    rPos = math.max(math.min(RrelBall-0.1, 2.5), 0.6);


  else
    rPos = math.max(math.min(RrelBall-0.7, 1), 0.3);

  end

  thetaRat = 0.1;

  thetaMe = math.atan2(goal_defend[2] - pose.y, goal_defend[1] - pose.x);
  thetaOtherDef = math.atan2(goal_defend[2] - otherDef[2], goal_defend[1] - otherDef[1]);

  if(thetaMe > thetaOtherDef) then
    --left defender
    thetaMe = aGoal + thetaRat;
  else
    --right defender
    thetaMe = aGoal - thetaRat;
  end


  homePosition = {};

  homePosition[1] = -4.5+math.cos(thetaMe)*rPos;
  homePosition[2] = math.sin(thetaMe)*rPos;
  homePosition[3] = math.atan2(relBallY, relBallX);

  --]]

  --Cartesian Plane, WORKS but not completely bug free
  if(posFB == 1) then
    xPos = math.max(math.min(ballGlobal[1], -2), -3.9);

  else --decreased minimum position
    xPos = math.max(math.min(ballGlobal[1]-0.7, -3.7), -4.7);

  end

  m = (ballGlobal[2]/(ballGlobal[1]+4.5));
  c = 4.5*m;


  yPos = m*xPos+c;

  --fixed value for ratio away from the line in terms of yPos, increases the further from Goal you are
  yRat = 0.1;

  if(posexya[2] > otherDef[2]) then
    --left defender
    yPos = yPos - ((xPos)*yRat);
  else
    --right defender
    yPos = yPos + ((xPos)*yRat);
  end

  homePosition = {};

  homePosition[1] = xPos;
  homePosition[2] = yPos;
  homePosition[3] = math.atan2(relBallY, relBallX);


  --constant defender pos
  --homePosition[1] = goal_defend[1];
  --homePosition[2] = goal_defend[2] + 0.5;
  --homePosition[3] = math.atan2(relBallY, relBallX);



  --print("Zdefender pose: ", pose.x, pose.y, pose.a*180/math.pi)
  --print("Zdefender homePose: ", homePosition[1], homePosition[2], homePosition[3]*180/math.pi)

  return homePosition;
end


function getZainiDefender2HomePose()
      --[[

  first determine the line from the ball to the goal

  y=mx+c where m=y1-y2/x1-x2  and c = 4.5*m
  Dont really need this? cant I just angle? no not for how Xiang wants this.



  next determine if I'm front or if I'm back (this should be done using the homepos and not actual position?)
  Lastly, determine where to stand on the radius

  x position should be determined based on a ratio, so lets just say at a fixed y position

  larger deviation above, smaller deviation below

  --]]


  local ball, pose = wcm.get_ball(), wcm.get_pose()
  local ballxy = vector.new({ball.x, ball.y, 0})
  local posexya = vector.new({pose.x, pose.y, pose.a})
  local ballGlobal = util.pose_global(ballxy, posexya)
  local aBall = math.atan2(ballGlobal[2] - pose.y, ballGlobal[1] - pose.x);
  local ballR = math.sqrt(ball.x^2 + ball.y^2);

  --TODO: check if the other defender is alive, could be based on TeamSPL role calculations.
  otherDef = wcm.get_team_defender_pose();
  local ballR2 = math.sqrt((ballGlobal[1] - otherDef[1])^2 + (ballGlobal[2]-otherDef[2])^2);

  goal_defend = wcm.get_goal_defend();
  relBallX = ballGlobal[1] - goal_defend[1];
  relBallY = ballGlobal[2] - goal_defend[2];
  RrelBall = math.sqrt(relBallX^2 + relBallY^2);

  prevPosFB = wcm.get_team_isFrontDef();

  --posFB 1 for front def, 0 for back, changed so that there is an impact on previous assignments in the allocation
  if (ballR - 0.2*prevPosFB < ballR2 - (0.2 - 0.2*prevPosFB)) then
    posFB = 1;
    wcm.set_team_isFrontDef(1);
  else
    posFB = 0;
    wcm.set_team_isFrontDef(0);
  end


  --POLAR COORDINATES, DOESNT WORK
  --[[
  aGoal = math.atan2(relBallX, relBallY);

  if(posFB == 1) then
    rPos = math.max(math.min(RrelBall-0.1, 2.5), 0.6);


  else
    rPos = math.max(math.min(RrelBall-0.7, 1), 0.3);

  end

  thetaRat = 0.1;

  thetaMe = math.atan2(goal_defend[2] - pose.y, goal_defend[1] - pose.x);
  thetaOtherDef = math.atan2(goal_defend[2] - otherDef[2], goal_defend[1] - otherDef[1]);

  if(thetaMe > thetaOtherDef) then
    --left defender
    thetaMe = aGoal + thetaRat;
  else
    --right defender
    thetaMe = aGoal - thetaRat;
  end


  homePosition = {};

  homePosition[1] = -4.5+math.cos(thetaMe)*rPos;
  homePosition[2] = math.sin(thetaMe)*rPos;
  homePosition[3] = math.atan2(relBallY, relBallX);

  --]]

  --Cartesian Plane, WORKS but not completely bug free
  if(posFB == 1) then
    xPos = math.max(math.min(ballGlobal[1], -2), -3.9);


  else --decreased minimum position
    xPos = math.max(math.min(ballGlobal[1]-0.7, -3.7), -4.5);

  end

  m = (ballGlobal[2]/(ballGlobal[1]+4.5));
  c = 4.5*m;


  yPos = m*xPos+c;

  --fixed value for ratio away from the line in terms of yPos, increases the further from Goal you are
  yRat = 0.1;

  if(posexya[2] > otherDef[2]) then
    --left defender
    yPos = yPos - ((xPos)*yRat);
  else
    --right defender
    yPos = yPos + ((xPos)*yRat);
  end

  homePosition = {};

  homePosition[1] = xPos;
  homePosition[2] = yPos;
  homePosition[3] = math.atan2(relBallY, relBallX);

  --constant defender pos
  --homePosition[1] = goal_defend[1];
  --homePosition[2] = goal_defend[2] - 0.5;
  --homePosition[3] = math.atan2(relBallY, relBallX);


  --print("Zdefender pose: ", pose.x, pose.y, pose.a*180/math.pi)
  --print("Zdefender homePose: ", homePosition[1], homePosition[2], homePosition[3]*180/math.pi)

  return homePosition;
end









supporter_pos = Config.team.supporter_pos or {0.5, 1.25};
maxSupporterX = Config.team.maxSupporterX;
defenderRangeX = Config.team.defenderRangeX;

function getSupporterHomePose()
  local ball, pose = wcm.get_ball(), wcm.get_pose()
  local ballxy = vector.new({ball.x, ball.y, 0})
  local posexya = vector.new({pose.x, pose.y, pose.a})
  local ballGlobal = util.pose_global(ballxy, posexya)
  local aBall = math.atan2(ballGlobal[2] - pose.y, ballGlobal[1] - pose.x);
  local ballR = math.sqrt(ball.x^2 + ball.y^2);

  local postAttack = Config.world.postYellow
  if gcm.get_team_color() == 1 then
    postAttack = Config.world.postCyan
  end

  local LPostX = postAttack[1][1]

  goal_defend = wcm.get_goal_defend();

  attackGoalPosition = vector.new(wcm.get_goal_attack());
  relBallX = ballGlobal[1] - goal_defend[1];
  relBallY = ballGlobal[2] - goal_defend[2];
  RrelBall = math.sqrt(relBallX^2 + relBallY^2) + 0.001;


  homePosition = {0, 0, 0};

  -- supporter x-coord depends on where we think the ball is
  ballGoalDist = ballGlobal[1] - goal_defend[1];
  -- print("ballGoalDist", ballGoalDist)
  -- if ballGoalDist < defenderRangeX then
  --   stay alongside the ball
    homePosition[1] = ballGlobal[1] - util.sign(LPostX)*supporter_pos[1];
  -- else
  --   -- if ball's in their half, move ahead of the ball but not right on top of the goal line
  --   homePosition[1] = math.min(ballGlobal[1] + 1, maxSupporterX);
  -- end

  -- using util.sign(ballGlobal[2]) if ball's close to centerline isn't a good idea (see util.sign)
  if math.abs(ballGlobal[2]) < 0.5 then
    homePosition[2] = util.sign(pose.y)*supporter_pos[2];
  else
    supporterOffset = -util.sign(ballGlobal[2])*supporter_pos[2];

    -- ensure supporter won't go out of bounds
    if math.abs(ballGlobal[2] + supporterOffset) < yFieldOffset then
      -- prevent the supporter from crossing in front of the ball
      -- crossing may get in the way of a kick and how it should turn is unclear, as well as time-consuming
      homePosition[2] = ballGlobal[2] + supporterOffset
    else
      homePosition[2] = ballGlobal[2] - supporterOffset
    end
  end

  relBallX = ballGlobal[1] - homePosition[1];
  relBallY = ballGlobal[2] - homePosition[2];

  -- face ball
  homePosition[3] = util.mod_angle(math.atan2(ball.y, ball.x) + pose.a);

  -- print("currPose ", pose.x, pose.y, pose.a*180/math.pi)
  -- print("Supporter homePose ", homePosition[1], homePosition[2], homePosition[3]*180/math.pi)

  return homePosition;
end



function getForwardHomePose()
  local ball, pose = wcm.get_ball(), wcm.get_pose()
  local ballxy = vector.new({ball.x, ball.y, 0})
  local posexya = vector.new({pose.x, pose.y, pose.a})
  local ballGlobal = util.pose_global(ballxy, posexya)
  local aBall = math.atan2(ballGlobal[2] - pose.y, ballGlobal[1] - pose.x);
  local ballR = math.sqrt(ball.x^2 + ball.y^2);

  local postAttack = Config.world.postYellow
  if gcm.get_team_color() == 1 then
    postAttack = Config.world.postCyan
  end

  local LPostX = postAttack[1][1]

  goal_defend = wcm.get_goal_defend();

  attackGoalPosition = vector.new(wcm.get_goal_attack());
  relBallX = ballGlobal[1] - goal_defend[1];
  relBallY = ballGlobal[2] - goal_defend[2];
  RrelBall = math.sqrt(relBallX^2 + relBallY^2) + 0.001;


  homePosition = {0, 0, 0};

  -- supporter x-coord depends on where we think the ball is
  ballGoalDist = ballGlobal[1] - goal_defend[1];
   print("ballGoalDist", ballGoalDist)
   if ballGoalDist < defenderRangeX then
  --   stay alongside the ball
    homePosition[1] = ballGlobal[1] - util.sign(LPostX)*supporter_pos[1];
    homePosition[1] = ballGlobal[1] - util.sign(LPostX)*supporter_pos[1];
   else
     -- if ball's in their half, move ahead of the ball but not right on top of the goal line
     homePosition[1] = math.min(ballGlobal[1] + 1, maxSupporterX);
   end

  -- using util.sign(ballGlobal[2]) if ball's close to centerline isn't a good idea (see util.sign)
  if math.abs(ballGlobal[2]) < 0.5 then
    homePosition[2] = util.sign(pose.y)*supporter_pos[2];
  else
    supporterOffset = -util.sign(ballGlobal[2])*supporter_pos[2];

    -- ensure supporter won't go out of bounds
    if math.abs(ballGlobal[2] + supporterOffset) < yFieldOffset then
      -- prevent the supporter from crossing in front of the ball
      -- crossing may get in the way of a kick and how it should turn is unclear, as well as time-consuming
      homePosition[2] = ballGlobal[2] + supporterOffset
    else
      homePosition[2] = ballGlobal[2] - supporterOffset
    end
  end

  relBallX = ballGlobal[1] - homePosition[1];
  relBallY = ballGlobal[2] - homePosition[2];

  -- face ball
  homePosition[3] = util.mod_angle(math.atan2(ball.y, ball.x) + pose.a);

  -- print("currPose ", pose.x, pose.y, pose.a*180/math.pi)
  -- print("Supporter homePose ", homePosition[1], homePosition[2], homePosition[3]*180/math.pi)

  return homePosition;
end









function getZainiSupporterHomePose()
  local ball, pose = wcm.get_ball(), wcm.get_pose()
  local ballxy = vector.new({ball.x, ball.y, 0})
  local posexya = vector.new({pose.x, pose.y, pose.a})
  local ballGlobal = util.pose_global(ballxy, posexya)
  local aBall = math.atan2(ballGlobal[2] - pose.y, ballGlobal[1] - pose.x);
  local ballR = math.sqrt(ball.x^2 + ball.y^2);

  local postAttack = Config.world.postYellow
  if gcm.get_team_color() == 1 then
    postAttack = Config.world.postCyan
  end

  local LPostX = postAttack[1][1]

  goal_defend = wcm.get_goal_defend();

  attackGoalPosition = vector.new(wcm.get_goal_attack());
  relBallX = ballGlobal[1] - goal_defend[1];
  relBallY = ballGlobal[2] - goal_defend[2];
  RrelBall = math.sqrt(relBallX^2 + relBallY^2) + 0.001;


  homePosition = {0, 0, 0};

  -- supporter x-coord depends on where we think the ball is
  ballGoalDist = ballGlobal[1] - goal_defend[1];
  -- print("ballGoalDist", ballGoalDist)
  -- if ballGoalDist < defenderRangeX then
  --   stay alongside the ball
    --homePosition[1] = ballGlobal[1] - util.sign(LPostX)*supporter_pos[1];
  -- else
  --   -- if ball's in their half, move ahead of the ball but not right on top of the goal line
     --if()
     --  homePosition[1] = ballGlobal[1] - util.sign(LPostX)*supporter_pos[1];
     --else
       homePosition[1] = math.max(0, math.min(ballGlobal[1] + 1, 3.8));
     --end
  -- end

  -- using util.sign(ballGlobal[2]) if ball's close to centerline isn't a good idea (see util.sign)
  if math.abs(ballGlobal[2]) < 0.5 then
    homePosition[2] = util.sign(pose.y)*supporter_pos[2];
  else
    supporterOffset = -util.sign(ballGlobal[2])*supporter_pos[2];

    -- ensure supporter won't go out of bounds
    if math.abs(ballGlobal[2] + supporterOffset) < yFieldOffset then
      -- prevent the supporter from crossing in front of the ball
      -- crossing may get in the way of a kick and how it should turn is unclear, as well as time-consuming
      homePosition[2] = ballGlobal[2] + supporterOffset
    else
      homePosition[2] = ballGlobal[2] - supporterOffset
    end
  end

  relBallX = ballGlobal[1] - homePosition[1];
  relBallY = ballGlobal[2] - homePosition[2];

  -- face ball
  homePosition[3] = util.mod_angle(math.atan2(ball.y, ball.x) + pose.a);

  -- print("currPose ", pose.x, pose.y, pose.a*180/math.pi)
  -- print("Supporter homePose ", homePosition[1], homePosition[2], homePosition[3]*180/math.pi)

  return homePosition;
end




function getGoalieHomePose() --Moving goalie home pose

  local ball, pose = wcm.get_ball(), wcm.get_pose()
  local ballxy = vector.new({ball.x, ball.y, 0})
  local posexya = vector.new({pose.x, pose.y, pose.a})
  local ballGlobal = util.pose_global(ballxy, posexya)

  local homePosition = 0.98*vector.new(wcm.get_goal_defend());
  local goal_defend = wcm.get_goal_defend();

  relBallX = ballGlobal[1] - goal_defend[1];
  relBallY = ballGlobal[2] - goal_defend[2];
  RrelBall = math.sqrt(relBallX^2 + relBallY^2) + 0.001;

  if tBall>5 or RrelBall > math.abs(homePosition[1]) then
    --Go back and face center
    relBallX = -goal_defend[1];
    relBallY = -goal_defend[2];
    homePosition[3] = 0;
  else --Move out
    dist = 0.60;
    homePosition[1] = homePosition[1] + dist*relBallX / RrelBall;
    homePosition[2] = homePosition[2] + dist*relBallY / RrelBall;
    homePosition[3] = util.mod_angle(math.atan2(relBallY, relBallX));
  end

--Don't let goalie go back until it comes to blocking position first
  uPose = vector.new({pose.x,pose.y,pose.a})
  homeRelative = util.pose_relative(homePosition, uPose);
  if math.abs(homeRelative[3]) > 20*math.pi/180 then
    posGoalX = pose.x - goal_defend[1];
    posGoalY = pose.y - goal_defend[2];
    posGoalR = math.sqrt(posGoalX^2 + posGoalY^2)*0.8;

    --Recalculate home position
    homePosition = 0.98*vector.new(wcm.get_goal_defend());
    homePosition[1] = homePosition[1] + posGoalR*relBallX / RrelBall;
    homePosition[2] = homePosition[2] + posGoalR*relBallY / RrelBall;
    homePosition[3] = util.mod_angle(math.atan2(relBallY, relBallX));
  end

  return homePosition;
end
