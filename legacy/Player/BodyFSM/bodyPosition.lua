module(..., package.seeall);

require('Body')
require('World')
require('walk')
require('vector')
require('wcm')
require('Config')
require('util')
require('walk')
require('behavior')
require('velgeneration')
require('gcm')


local log = require 'log';
if Config.log.enableLogFiles then
    log.outfile = (Config.log.behaviorFile);
end
log.level = Config.log.logLevel;

t0 = 0;

tLost = Config.fsm.bodyPosition.tLost;
timeout = Config.fsm.bodyPosition.timeout;
thClose = Config.fsm.bodyPosition.thClose;
rClose = Config.fsm.bodyPosition.rClose; -- for checking if we're close enough to ball
rCloseDefender = Config.team.rCloseDefender; -- for checking if non-attackers are close enough to their homePose

test_teamplay = Config.team.test_teamplay or 0;
closeAngle = Config.team.closeAngle or 20*math.pi/180;


function entry()
  log.info(_NAME.." entry");
  t0 = Body.get_time();
  max_speed = 0;
  count = 0;
  behavior.update();
  step_count = 0;
  closeToPose = false;
  closeToAngle = false;
end


function update()
  --shouldn't be here if we are goalie
  local role = gcm.get_team_role()
  if role == 0 then
    log.debug('Transition: goalie')
    return "goalie"
  end

  --update some info from shm
  count = count + 1;
  local t = Body.get_time();
  ball = wcm.get_ball();
  pose = wcm.get_pose();
  ballR = math.sqrt((ball.x)^2 + (ball.y)^2);

	--recalculate approach path when ball is far away
  if ballR > 0.60 then
    behavior.update()
  end

  --figure out where we should be going
  local homePose = targetpose.getRoleSpecificHomePose()
  -- if role == 1 then
  --   print("homePose x, y", homePose[1], homePose[2])
  -- end

  gcm.set_game_walkingto({homePose[1], homePose[2]})
  local vx, vy, va = velgeneration.getRoleSpecificVelocity(homePose)

  -- if robot doesn't need to move, transition out
  if vx == 0 and vy == 0 and va == 0 and role ~= 1 then
    return "trackTeamBall"
  end

  --In teamplay test mode, immobilize everybody
  if test_teamplay == 1 then
    vx, vy, va = 0, 0, 0;
    walk.stop();
    log.debug('Transition: Test Team play')
    return "timeout" --to stay here and stay immobile 
  end

  --set velocity with proper speed
  walk.set_velocity(vx,vy,va);
  if Config.fsm.velocity_testing then
    log.warn(vx, " ", vy, " ", va, " 1");
  end

  --Escape checks
  if (t - ball.t > tLost) and wcm.get_robot_use_team_ball() == 0 then 
    log.debug('Transition: ballLost')
    return "ballLost" 
  end
  if (t - t0 > timeout) then
    log.debug('Transition: timeout')
    return "timeout"
  end

  -- check how close we are to desired position
  local uPose = vector.new({pose.x, pose.y, pose.a})
  local homeRelative = util.pose_relative(homePose, uPose);

  
  
  if role == 1 then
    closeToPose = math.abs(homeRelative[1]) < thClose[1] and
    math.abs(homeRelative[2]) < thClose[2];
  else
    closeToPose = math.sqrt(homeRelative[1]^2 + homeRelative[2]^2) < rCloseDefender
    -- if role == 2 then
    --   print("defender closeToPose", closeToPose)
    -- end
  end
   
  --Check angle
    closeToAngle = math.abs(homeRelative[3]) < closeAngle;

  if closeToPose then
     log.debug('closeToPose')
    -- print(closeToAngle, util.mod_angle(math.atan2(ball.y, ball.x)) < 30*math.pi/180)

    -- we only check if ball's close here, but shouldn't we always check if ball's close?
    -- it may be ok to not check beause teamSPL can change role based on ETA, and then robot's
    -- homePose will be close to ball, but in principle it would be good to always check
    if ballR < rClose and t - ball.t < 0.5 and ball.p > 0.5 then
      -- print(homeRelative[3]*180/math.pi)

      -- if our position and orientation make us close to the ball, go to bodyApproach
      if closeToAngle then
        log.debug('Transition: done')
        return "done";

      -- if we're close to ball but not facing where we want, go to bodyOrbit
      else
        log.debug('Transition: ballClose')
        return "ballClose";
      end

    -- If we aren't attacker nor supporter and team knows where ball is and we are close to our homePose, 
    -- face the ball and don't move
    elseif closeToAngle and role ~= 1 and
      wcm.get_robot_use_team_ball() == 1 and util.mod_angle(math.atan2(ball.y, ball.x)) < closeAngle then
      log.debug('Transition: trackTeamBall') 
      return "trackTeamBall";
    end
  end -- end for if closeToPose block
end --update function

function exit()
end
