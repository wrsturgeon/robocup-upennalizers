module(..., package.seeall);

require('Body')
require('walk')
require('vector')
require('Config')
require('wcm')
require('behavior')

local log = require 'log';
if Config.log.enableLogFiles then
    log.outfile = (Config.log.behaviorFile);
end
log.level = Config.log.logLevel;

t0 = 0;
timeout = Config.fsm.bodyOrbit.timeout;
maxStep = Config.fsm.bodyOrbit.maxStep;
turnWeight = Config.fsm.bodyOrbit.turnWeight;
rOrbit = Config.fsm.bodyOrbit.rOrbit;
rFar = Config.fsm.bodyOrbit.rFar;
thAlign = Config.fsm.bodyOrbit.thAlign;
tLost = Config.fsm.bodyOrbit.tLost;
direction = 1;
dribbleThres = 0.75;

kickAngle = 0;

function entry()
  print(_NAME.." entry");
  t0 = Body.get_time();
  behavior.update();
  kickAngle = wcm.get_kick_angle();
  direction,angle = get_orbit_direction();
end

function get_orbit_direction()
  attackBearing = wcm.get_attack_bearing();
  angle = util.mod_angle(attackBearing -
    kickAngle);

  ball, pose = wcm.get_ball(), wcm.get_pose()
  local ballxy = vector.new( {ball.x, ball.y, 0})
  local posexya = vector.new( {pose.x, pose.y, pose.a})
  local ballGlobal = util.pose_global(ballxy, posexya)


  goal_attack = wcm.get_goal_attack()
  ballToGoalAngle = math.atan2(goal_attack[2] - ballGlobal[2], goal_attack[1] - ballGlobal[1])
  -- print("who dis", attackBearing, ballToGoalAngle)

  if angle > 0 then dir = 1;
  else dir = -1;
  end
  return dir,angle;
end

function update()
  local t = Body.get_time();

  --print('attackBearing: '..attackBearing);
  --print('daPost: '..daPost);
  --print('attackBearing', attackBearing)
  ball = wcm.get_ball();

  ballR = math.sqrt(ball.x^2 + ball.y^2);
  ballA = math.atan2(ball.y, ball.x + 0.10);
  orbitError = ballR - rOrbit;
  aStep = ballA - direction*(90*math.pi/180 - orbitError/0.40);
  vx = maxStep*math.cos(aStep);

  --Does setting vx to 0 improve performance of orbit?--

  --vx = 0;

  vy = maxStep*math.sin(aStep);
  va = turnWeight*ballA;

  walk.set_velocity(vx, vy, va);
  -- print("bodyOrbit v", vx, vy, va)
  if Config.fsm.velocity_testing then
     log.warn(vx, " ", vy, " ", va, " 5");
  end

  if (t - ball.t > tLost) then
    return 'ballLost';
  end
  if(wcm.get_kick_freeKick() == 2) then 
    return 'freeKick';
  end
  if (t - t0 > timeout) then
    return 'timeout';
  end
  if (ballR > rFar) then
    print("ballR > rFar; transition out of bodyOrbit")
    return 'ballFar';
  end
--  print(attackBearing*180/math.pi)

  dir,angle = get_orbit_direction();


  is_confused = wcm.get_robot_is_confused();

  if (math.abs(angle) < thAlign) or is_confused > 0 then
    return 'done';
  end

  --Overshoot escape
  -- print("overshoot check", direction, dir)
  if direction ~= dir then
    -- print("bodyOrbit overshoot")
    return 'done'
  end

end

function exit()
end
