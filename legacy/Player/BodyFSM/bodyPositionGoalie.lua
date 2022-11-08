module(..., package.seeall);

require('Body')
require('walk')
require('vector')
require('util')
require('Config')
require('wcm')
require('gcm')
require('UltraSound')
require('position')

log = require 'log';
--log.outfile = ("Logs/BodyFSMLog.txt");
log.level = "debug";
currLoggedHomePose = {-9, -9, -9};
logHomePoseThresh = {0.4, 0.4, 0.15}; -- threshold changes in x, y, and angle to log another desired homePose value

t0 = 0;

--[[
maxStep = Config.fsm.bodyChase.maxStep;
tLost = Config.fsm.bodyChase.tLost;
timeout = Config.fsm.bodyChase.timeout;
rClose = Config.fsm.bodyChase.rClose;
--]]

timeout = 20.0;
maxStep = 0.04;
maxPosition = 0.55;
tLost = 10.0;
tLastSearch = 0.0;

rClose = Config.fsm.bodyAnticipate.rClose;
rCloseX = Config.fsm.bodyAnticipate.rCloseX;
thClose = Config.fsm.bodyGoaliePosition.thClose;
goalie_type = Config.fsm.goalie_type;

function entry()
	log.debug(_NAME.." entry");
  print(_NAME.." entry");
  t0 = Body.get_time();
  if goalie_type > 2 then
    HeadFSM.sm:set_state('headSweep');
  else
    HeadFSM.sm:set_state('headScan');
  end
end

function update()
  role = gcm.get_team_role();
  if role~=0 then
    return "player";
  end

  local t = Body.get_time();

  ball = wcm.get_ball();
  pose = wcm.get_pose();
  ballGlobal = util.pose_global({ball.x, ball.y, 0}, {pose.x, pose.y, pose.a});

  --moving goalie
  if goalie_type < 3 then 
    homePose = position.getGoalieHomePose();
		--if (math.abs(homePose[1] - currLoggedHomePose[1]) > logHomePoseThresh[1]) or
			--(math.abs(homePose[2] - currLoggedHomePose[2]) > logHomePoseThresh[2]) or
			--(math.abs(homePose[3] - currLoggedHomePose[3]) > logHomePoseThresh[3]) then
			--log.info("new desired position (x, y, radians):", homePose[1], homePose[2], homePose[3]);
		--end
  else
    --diving goalie
    homePose = position.getGoalieHomePose2();
    homePose = position.getGoalieHomePose();
  end

  -- vx,vy,va=position.setDefenderVelocity(homePose);
  vx, vy, va = position.setGoalieVelocity0(homePose);


  walk.set_velocity(vx, vy, va);

  goal_defend = wcm.get_goal_defend();
  ballxy = vector.new({ball.x,ball.y,0});
  posexya = vector.new({pose.x, pose.y, pose.a});
  ballGlobal = util.pose_global(ballxy, posexya);
  ballR_defend = math.sqrt(
		(ballGlobal[1] - goal_defend[1]) ^ 2 +	(ballGlobal[2] - goal_defend[2]) ^ 2);
  ballX_defend = math.abs(ballGlobal[1] - goal_defend[1]);

	uPose = vector.new({pose.x,pose.y,pose.a})
  homeRelative = util.pose_relative(homePose, uPose);  
  rHomeRelative = math.sqrt(homeRelative[1]^2 + homeRelative[2]^2);
  -- If we are close enough to the home position, then transition to bodyAnticipate.
  if goalie_type > 1 and 
    rHomeRelative < math.sqrt(thClose[1] ^ 2 + thClose[2] ^ 2) and
    math.abs(homePose[3] - pose.a) < thClose[3] then
		log.debug("bodyPositionGoalie finished; position is", pose.x, pose.y, pose.a);
		print("bodyPositionGoalie finished; position is " .. pose.x .. " " .. pose.y .. " " .. pose.a);
    return "ready";
  end

  rCloseX2 = 0.8;
  eta_kickaway = 3.0;
  attacker_eta = wcm.get_team_attacker_eta();

	if t - ball.t < 2.0 then
    if ballX_defend < 0.7 or
--       ((ballR_defend<rClose or ballX_defend<rCloseX) 
       (ballR_defend < 0.7 
         and attacker_eta > eta_kickaway) then
      return "ballClose";
    end
  end

	if t - ball.t > tLost and rHomeRelative < math.sqrt(thClose[1] ^ 2 + thClose[2] ^ 2) and math.abs(homePose[3] - pose.a) < thClose[3]then
		print("Ball lost during bodyPositionGoalie; searching");
    print("t - ball.t: ", t - ball.t);
    print("t - tLastSearch: ", t - tLastSearch);
		tLastSearch = t;
		return "ballLost";
	end

	--[[if t - t0 > timeout then
		print ("timeout; transitioning to bodyPositionGoalie");
		return "timeout";
	end--]]
end

function exit()
  if goalie_type > 2 then
    HeadFSM.sm:set_state('headTrack');
  end
end
