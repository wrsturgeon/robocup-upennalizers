module(..., package.seeall);
require('Body')
require('walk')
require('vector')
require('Config')
require('wcm')
require('gcm')


local log = require 'log';
if Config.log.enableLogFiles then
    log.outfile = (Config.log.behaviorFile);
end
log.level = Config.log.logLevel;

rTurn= Config.fsm.bodyPosition.rTurn;
rTurn2= Config.fsm.bodyPosition.rTurn2;

maxStep1 = Config.fsm.bodyPosition.maxStep1;

maxStep2 = Config.fsm.bodyPosition.maxStep2;
rVel2 = Config.fsm.bodyPosition.rVel2 or 0.5;
aVel2 = Config.fsm.bodyPosition.aVel2 or 45*math.pi/180;
maxA2 = Config.fsm.bodyPosition.maxA2 or 0.2;
maxY2 = Config.fsm.bodyPosition.maxY2 or 0.02;

maxStep3 = Config.fsm.bodyPosition.maxStep3;
rVel3 = Config.fsm.bodyPosition.rVel3 or 0.8;
aVel3 = Config.fsm.bodyPosition.aVel3 or 30*math.pi/180;
maxA3 = Config.fsm.bodyPosition.maxA3 or 0.1;
maxY3 = Config.fsm.bodyPosition.maxY3 or 0;

minX = Config.fsm.bodyPosition.minX or -0.1;


if Config.use_planner then
  rVel2 = 0.1
  rVel3 = 0.3
end


--This file calculates the velocity to reach the target pose

function getPlanHomepose()

  posei = wcm.get_pose();
  local traj_num = wcm.get_robot_traj_num()
  local traj_x = wcm.get_robot_traj_x()
  local traj_y = wcm.get_robot_traj_y()
  if traj_num<10 then return end

  local min_dist = 999
  local min_idx
  for i = 1,math.min(traj_num,9) do
    local dist = (traj_x[i] - pose.x)^2 + (traj_y[i] - pose.y)^2;
    if dist < min_dist then
      dist = min_dist
      min_idx = i
    end
  end
  local target_pose = {traj_x[min_idx], traj_y[min_idx]}
  target_pose[3] = math.atan2(
    traj_y[min_idx + 1] - traj_y[min_idx],
    traj_x[min_idx + 1] - traj_x[min_idx]
    )
  return target_pose
end


function getRoleSpecificVelocity(homePose)

  if Config.use_planner then
    local homepose_plan = getPlanHomepose()
    if homepose_plan then homePose = homepose_plan end
  end

  role = gcm.get_team_role()
  if role == 1 then
    -- if attacker
    return getAttackerVelocity(homePose)
  else
    return getDefenderVelocity(homePose)
  end
end

function getReadyVelocity(homePose,phase)

  if Config.use_planner then
    local homepose_plan = getPlanHomepose()
    if homepose_plan then homePose = homepose_plan end
  end

  local maxStep = Config.fsm.bodyReady.maxStep;
  pose = wcm.get_pose();
  uPose = vector.new({pose.x,pose.y,pose.a})
  homeRelative = util.pose_relative(homePose, uPose);
  homeRelative[3] = util.mod_angle(homeRelative[3])
  rHomeRelative = math.sqrt(homeRelative[1]^2 + homeRelative[2]^2);
  aHomeRelative = math.atan2(homeRelative[2],homeRelative[1]);
  local vx, vy = maxStep*homeRelative[1]/rHomeRelative, maxStep*homeRelative[2]/rHomeRelative
  local va =  .2 * aHomeRelative
  if phase == 2 then va = .2 * homeRelative[3] end

  vx, vy, va = checkObstacle(vx,vy,va)

  return vx, vy, va, rHomeRelative, homeRelative[3]
end

function getAttackerVelocity(homePose)
  -- get current pose
  pose = wcm.get_pose();
  currPose = vector.new({pose.x, pose.y, pose.a});

  -- x, y distance to homePose, and angle difference between currPose and homePose angles, from reference frame of currPose
  homeRelative = util.pose_relative(homePose, currPose);

  -- distance from currPose to homePose
  rHomeRelative = math.sqrt(homeRelative[1]^2 + homeRelative[2]^2);

  -- angle from currPose position to homePose position w/resp to currPose coordinate axes
  aHomeRelative = math.atan2(homeRelative[2], homeRelative[1]);
  homeRot = math.abs(aHomeRelative);

  -- Distance-specific velocity generation
  veltype = 0;

  if rHomeRelative > rVel3 and homeRot < aVel3 then --Fast front dash
    maxStep, maxA, maxY, veltype = maxStep3, maxA3, maxY3, 1
  elseif rHomeRelative > rVel2 and homeRot < aVel2 then --Medium speed
    maxStep, maxA, maxY, veltype = maxStep2, maxA2, maxY2, 2
  else --Normal speed
    maxStep, maxA, maxY, veltype = maxStep1, maxA2, 999, 3
  end

  vx, vy, va = 0, 0, 0;

  -- calcalate vx, vy

  vx = math.max(
    maxStep*homeRelative[1]/(rHomeRelative + 0.001), -- 0.001 to get rid of NaN
    minX);


  --Sidestep more if ball is close and sideby
  if rHomeRelative < rVel2 and math.abs(aHomeRelative) > 45*180/math.pi then
    vy = maxStep*homeRelative[2]/rHomeRelative;
    aTurn = 1; --Turn toward the goal
  else
    vy = 0.5*maxStep*homeRelative[2]/rHomeRelative;
  end

  -- vy = maxStep*homeRelative[2]/rHomeRelative;
  vy = math.max(-maxY, math.min(maxY, vy));

  -- calcalate va
  aTurn = math.exp(-0.5*(rHomeRelative/rTurn)^2); -- gaussian curve
  if rHomeRelative < 0.3 then
    --Don't turn to ball if close
    aTurn = math.max(0.5, aTurn)
  end

	va = 0.5*
    (aTurn*homeRelative[3] + --Turn toward the desired final orientation
    (1 - aTurn)*aHomeRelative); --Turn in the direction we're currently moving towards

  va = math.max(-maxA, math.min(maxA, va)); --Limit rotation

  --va = 0;
  -- x and y distance betw. ball and homePose, calculated relative to robot's reference frame
  -- ball = wcm.get_ball();
  --xBallHomePose = homeRelative[1] - ball.x;
  --yBallHomePose = homeRelative[2] - ball.y;
  --rBallHomePose = math.sqrt(xBallHomePose^2 + yBallHomePose^2);
  --rBall = math.sqrt(ball.x^2 + ball.y^2);

  -- if the ball is close enough, set vx to 0 and just move around the ball
  -- if veltype == 2 and rBall < rBallHomePose then
  --   vx = 0;
  --   print("close enough to ball; vx set to 0");
  -- end

  -- print("vx, vy", vx, vy)

  --NaN Check
  if (not (vx < 0) and not (vx >= 0)) or (not (vy < 0) and not (vy >= 0)) or (not (va < 0) and not (va >= 0)) then
    vx, vy, va = 0, 0, 0;
    log.debug("ATTACKER: VELOCITY NAN!")
  end
  return checkObstacle(vx, vy, va)
end

rCloseDefender = Config.team.rCloseDefender;
maxTurnError = Config.team.maxTurnError;
closeAngle = Config.team.closeAngle;
function getDefenderVelocity(homePose)
  pose = wcm.get_pose();

  -- x, y distance to homePose, and angle difference between currPose and homePose angles
  -- from reference frame of currPose
  homeRelative = util.pose_relative(homePose, {pose.x, pose.y, pose.a});

  -- distance from currPose to homePose
  rHomeRelative = math.sqrt(homeRelative[1]^2 + homeRelative[2]^2);

  -- angle from currPose position to homePose position w/resp to currPose coordinate axes
  aHomeRelative = math.atan2(homeRelative[2], homeRelative[1]);
  homeRot = math.abs(aHomeRelative);

  if rHomeRelative > rVel3 and homeRot < aVel3 then
    maxStep, maxA, maxY, veltype = maxStep2, maxA3, maxY3, 1 -- medium speed
--    if max_speed==0 then Speak.play('./mp3/max_speed.mp3',50) end
    max_speed = 1
  -- elseif rHomeRelative > rVel2 and homeRot < aVel2 then --Medium speed
  --   maxStep, maxA, maxY, veltype = maxStep2, maxA2, maxY2, 2
  -- elseif rHomeRelative > 0.40 then
  --   maxStep, maxA, maxY, veltype = maxStep1, 999, 999, 3
  -- elseif rHomeRelative > 0.20 then
  --   maxStep, maxA, maxY, veltype = 0.02, 999, 999, 3
  -- else
  --   maxStep, maxA, maxY, veltype = 0.001, 999, 999, 3
  else --Medium speed
    maxStep, maxA, maxY, veltype = maxStep1, maxA2, maxY2, 2
  end

  vx, vy, va = 0, 0, 0;

  vx = math.max(
    maxStep*homeRelative[1]/(rHomeRelative + 0.001), -- 0.001 to get rid of NaN
    minX);


  vy = maxStep*homeRelative[2]/rHomeRelative;

  vy = math.max(-maxY, math.min(maxY, vy));

  -- if we're within rCloseDefender of homePose we can stop.
  if rHomeRelative < rCloseDefender then
    vx = 0;
    vy = 0;
  end

  -- va = 0.5*(aTurn*homeRelative[3] --Turn toward the target direction
  --   + (1 - aTurn)*aHomeRelative); --Turn toward the target


  -- if we're getting close to homePose x and y but it's not in the direction of homePose[3],
  -- don't turn towards homePose since that would be counterproductive in the long term
  -- if rHomeRelative < 2.5*rCloseDefender and math.abs(homeRelative[3] - aHomeRelative) > maxTurnError then
  --   -- print("va = homeRelative[3]")
  --   va = homeRelative[3]
  -- elseif rHomeRelative < rCloseDefender then
  --   -- print("va = homeRelative[3]")
  --   va = homeRelative[3]
  -- else
  --   -- print("va = aHomeRelative")
  --   va = aHomeRelative
  -- end

  if rHomeRelative < rCloseDefender then
    if math.abs(homeRelative[3]) > closeAngle then
      va = homeRelative[3]
    else
      --Don't turn if we're close to overall desired pose
      va = 0
    end
  else
    -- print("va = aHomeRelative")
    va = aHomeRelative
  end

-- -- calcalate va
--   aTurn = math.exp(-0.5*(rHomeRelative/rTurn)^2); -- gaussian curve

--   if rHomeRelative < 0.3 then
--     --Don't turn to ball if close
--     aTurn = math.max(0.5, aTurn)
--   end

--   if rHomeRelative < rCloseDefender and math.abs(aHomeRelative) > 45*math.pi/180 then
--     aTurn = 1; --Turn toward the desired final orientation
--   end

--   va = 0.5*
--     (aTurn*homeRelative[3] + --Turn toward the desired final orientation
--     (1 - aTurn)*aHomeRelative); --Turn in the direction we're currently moving towards

  va = math.max(-maxA, math.min(maxA, va)); --Limit rotation

  --NaN Check
  if (not (vx < 0) and not (vx >= 0)) or
    (not (vy < 0) and not (vy >= 0)) or
    (not (va < 0) and not (va >= 0)) then
    log.debug("DEFENDER: VELOCITY NAN!")
    log.debug("maxStep:", maxStep)
    log.debug("v:", vx, vy, va)
    log.debug("HomePose:", unpack(homePose));
    log.debug("HomeRelative:", unpack(homeRelative));
    log.debug("aHomeRelative:", aHomeRelative*180/math.pi);
    vx, vy, va = 0, 0, 0;
  end

  -- if gcm.get_team_role() == 2 then
  --   print("getDefenderVelocity(): ", vx, vy, va)
  -- end
  return checkObstacle(vx, vy, va)
end


-- function setGoalieVelocity()
--   maxStep = 0.04;
--   homePosition = 0.98*vector.new(wcm.get_goal_defend());
--   homeRelative = util.pose_relative(homePosition, {pose.x, pose.y, pose.a});
--   rHomeRelative = math.sqrt(homeRelative[1]^2 + homeRelative[2]^2);
--   aHomeRelative = math.atan2(homeRelative[2], homeRelative[1]);

-- --Basic velocity generation
--   vx = maxStep*homeRelative[1]/rHomeRelative;
--   vy = maxStep*homeRelative[2]/rHomeRelative;
--   rTurn = 0.3;
--   aTurn = math.exp(-0.5*(rHomeRelative/rTurn)^2);
--   vaTurn = .2*aHomeRelative;
--   vaGoal = .35*homeRelative[3];
--   --va = aTurn * vaGoal + (1-aTurn)*vaTurn;
--   --game hack
--   va = vaGoal;
--   --NaN Check
--   if (not (vx < 0) and not (vx >= 0)) or
--     (not (vy < 0) and not (vy >= 0)) or
--     (not (va < 0) and not (va >= 0)) then
--     vx, vy, va = 0, 0, 0;
--   --  print("VELOCITY NAN!")

--   end

--   return vx, vy, va;
-- end


--Function to ensure body search checks for obstacles
function bodySearchVelocity(spinSpeed,direction)

    vx,vy,va = 0,0,direction*spinSpeed;

    return checkObstacle(vx,vy,va);
end


function checkObstacle(vx, vy, va)
  role = gcm.get_team_role()
  local ball = wcm.get_ball();

  local game_state = gcm.get_game_state() --3 for playing
  local r_reject,v0_reject =  0.6, 0.1
  if game_state==1 then v0_reject = 0.2 end --Ready state

  oldvx, oldvy, oldva = vx, vy, va;

  pose = wcm.get_pose();
  uPose = vector.new({pose.x,pose.y,pose.a})

  --Check the nearby obstacle
  obstacle_num = wcm.get_obstacle_num();
  obstacle_x = wcm.get_obstacle_x();
  obstacle_y = wcm.get_obstacle_y();
  obstacle_dist = wcm.get_obstacle_dist();
  obstacle_role = wcm.get_obstacle_role();
  obstacle_radius = wcm.get_obstacle_radius();

  for i = 1, obstacle_num do
--print(string.format("%d XYD:%.2f %.2f %.2f",
--i,obstacle_x[i],obstacle_y[i],obstacle_dist[i]))

    if role==0 then r_reject = 0.5 --GOALIE
    elseif role==1 then r_reject = 0.001 --attacker
    end

    if obstacle_role[i]==0 then --obstacle is the our goalie
      r_reject = 1.0
    end

    if(obstacle_role[i] >= 10) then --maybe should be larger than???
        r_reject = obstacle_radius[i]
    end

    if obstacle_dist[i]<r_reject then
      --obstacles need to be relative to robot
      obstacle = {obstacle_x[i], obstacle_y[i], 0};
      relObst = util.pose_relative(obstacle, uPose);

      local v_reject = v0_reject*math.exp(-(obstacle_dist[i]/r_reject)^2);
      vx = vx - relObst[1]/obstacle_dist[i]*v_reject;
      vy = vy - relObst[2]/obstacle_dist[i]*v_reject;

      --TODO
    end
  end

  --Check ultrasound obstacles - brute force right now, should be more clever later
  if not(role == 1 and ball.t < 1) then--should only ignore obstacles if you are attacker and can see ball
	  leftblocked,rightblocked = UltraSound.check_obstacle();
	  if leftblocked and rightblocked then
		  vx = -0.02;
		  vy = 0;
		  va = 0;
	  elseif leftblocked and not rightblocked then
		  vx = -0.01;
		  vy = 0;
		  va = -0.3;
	  elseif not leftblocked and rightblocked then
		  vx = -0.01;
		  vy = 0;
		  va = 0.3;
	  end
  end

  if oldvx ~= vx or oldvy ~= vy or oldva ~= va then
    -- print("checkObstacle() changed velocity")
    -- print(oldvx, vx, oldvy, vy, oldva, va)
  end
  return vx, vy, va
end
