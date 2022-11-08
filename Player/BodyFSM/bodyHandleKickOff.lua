module(..., package.seeall)

require('Body')
require('World')
require('vector')
require('wcm')
require('Config')
require('util')
require('walk')
require('behavior')
require('velgeneration')
require('gcm')
require('mcm')
require('Speak')

local log = require 'log';
if Config.log.enableLogFiles then
	log.outfile = (Config.log.behaviorFile);
end
log.level = Config.log.logLevel;

local kickOffTimeOut = 0
local dist = 0
local heard_whistle = 0;

t0 = 0
test_teamplay = Config.team.test_teamplay or 0

walktimeout = 0;
tLost = Config.fsm.bodyPosition.tLost;
thClose = {0.3, 0.3};
rClose = Config.fsm.bodyPosition.rClose;

function entry()
  log.info(_NAME.." entry")
  log.debug("gcm.get_game_kickoff() = " .. gcm.get_game_kickoff())

  t0 = Body.get_time()
  heard_whistle = gcm.get_game_kickoff_from_whistle();
	if(heard_whistle == 1 and gcm.get_game_kickoff() ~= 1) then
		wcm.set_obstacle_kickOffTime(t0);
	else
		wcm.set_obstacle_kickOffTime(-11);
	end
  gcm.set_game_kickoff_from_whistle(0);
  log.debug("Heard whistle = ", heard_whistle)
  max_speed = 0
  count = 0
  behavior.update()
  step_count = 0

  ballR0 = vcm.get_ball_r()   --the ball distance from vcm is more reliable
  pose = wcm.get_pose()
  if ballR0 > 0 then
	dist = ballR0
  else
	dist = math.sqrt(pose.x^2 + pose.y^2)
  end
  dist = math.min(dist, 5);



--kickoff penaly isnt used anymore since we have obstacle detection. Zaini 2019
  if heard_whistle == 1 then
		if gcm.get_team_role() == 1 then
	  	kickOffTimeOut = 0;
	  	print("kickOffTimeOut set to ", kickOffTimeOut)
		else
	  	kickOffTimeOut = 0;
		end
  else
		kickOffTimeOut = 0;
  end




  log.debug("kickoff time: "..kickOffTimeOut)
  walk.stop();
  log.debug("My role is", gcm.get_team_role())
end

function update()
  t = Body.get_time();
  ball = wcm.get_ball();

	--our kickoff
  if gcm.get_game_kickoff() == 1 then
		-- attacker behavior
		if gcm.get_team_role() == 1 then
		  returnType = AttackerGoToCenter();
			if returnType == 1 then
				log.debug("Transition: ourTurn (our kickoff attacker)");
				return "ourTurn"
		  end

		-- supporter behavior
		elseif gcm.get_team_role() == 3 then
		  returnType = SupporterGoForward();
		  if returnType == 1 then
				log.debug("Transition: ourTurn (our kickoff supporter)");
				return "ourTurn"
		  end

		-- all other players don't do anything specific
		else
		  log.debug("Transition: ourTurn (our kickoff not attacker)");
		  return "ourTurn"
		end
  end

  --behavior after timeout (also functions as behavior for opponents' kickoff)
  if t - t0 > kickOffTimeOut then
  	if (t - ball.t < 1) then
  	  log.debug('Transition: Ball free')
  	  walk.set_velocity(0, 0, 0)
  	  walk.start()
  	  Motion.event('walk')
  	  return 'ballFree'
  	else
      if gcm.get_team_role()  == 1 then
  		  returnType = AttackerGoToCenter();
        if returnType == 1 then
    		  log.debug("Transition: ourTurn (not our kickoff attacker)");
    		  return "ourTurn"
    		end
  	  else
    		log.debug("Transition: ourTurn (not our kickoff not attacker)");
    		return "ourTurn"
  	  end  --if role == 1
  	end --if ball not seen
  end --if timeout is passed
end -- function update

function exit()
end

function AttackerGoToCenter()
  if walk.active == false then
		walk.start()
  end

  homePose = {0, 0, 0};
  gcm.set_game_walkingto({homePose[1], homePose[2]})
  local vx, vy, va = velgeneration.getRoleSpecificVelocity(homePose)
  walk.set_velocity(vx, vy, va);

  if Config.fsm.velocity_testing then
    log.warn(vx, " ", vy, " ", va, " 9");
  end

  --how close are we to our desired position?
  local pose = wcm.get_pose();
  local uPose = vector.new({pose.x,pose.y,pose.a})
  local homeRelative = util.pose_relative(homePose, uPose);

  --check positioning
  if math.abs(homeRelative[1]) < thClose[1] and
    math.abs(homeRelative[2]) < thClose[2] then
    closeToPose = 1;
  else
    closeToPose = 0;
  end
  t = Body.get_time();

  ball = wcm.get_ball();
  ballR = vcm.get_ball_r();
  if ballR < rClose and t - ball.t < 1.0 and ball.p > 0.5 then
		log.debug('AttackerGoToCenter: Ball Close')
		return 1;
  end

  if closeToPose == 1 then
		log.debug('AttackerGoToCenter: Close to pose')
		return 1;
  end

  if (t - t0 > kickOffTimeOut + walktimeout) then
		log.debug('AttackerGoToCenter: timeout');
		return 1
  end

  return 0;
end

function SupporterGoForward()
  if walk.active == false then
		walk.start()
  end

  -- walk forward to center line and turn towards the middle of the field
  homePose = {0, 1, -math.pi/8};
  gcm.set_game_walkingto({homePose[1],homePose[2]})
  local vx, vy, va = velgeneration.getRoleSpecificVelocity(homePose)
  walk.set_velocity(vx, vy, va);

  --check positioning
  local pose = wcm.get_pose();
  local currPose = vector.new({pose.x, pose.y, pose.a});
  local homeRelative = util.pose_relative(homePose, currPose);
  if math.abs(homeRelative[1]) < thClose[1] and
		math.abs(homeRelative[2]) < thClose[2] then
		closeToPose = 1;
  else
		closeToPose = 0;
  end

  t = Body.get_time();
  ball = wcm.get_ball();
  ballR = vcm.get_ball_r();
  if ballR < rClose and t - ball.t < 1.0 and ball.p > 0.35 then
		log.debug('Supporter kickoff: Ball close')
		return 1;
  end

  if closeToPose == 1 then
		log.debug('Supporter kickoff: Close to homePose')
		return 1;
  end

  if (t - t0 > kickOffTimeOut + walktimeout) then
		log.debug('Walk to center: timeout');
		return 1
  end

  -- print("SupporterGoForward finished 1 cycle");
  return 0;
end
