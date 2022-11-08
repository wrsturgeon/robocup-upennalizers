module(..., package.seeall);

require('Body')
require('walk')
require('vector')
require('Config')
require('wcm')
require('mcm')
require('velgeneration')

t0 = 0;
direction = 1;

vSpin = Config.fsm.bodySearchGoalie.vSpin or 0.3;
turnAngleLimit = Config.fsm.bodySearchGoalie.turnAngleLimit or math.pi / 2;
thClose = Config.fsm.bodyGoaliePosition.thClose;
timeout = Config.fsm.bodySearchGoalie.timeout or 3.5*Config.speedFactor;
sidesSearched = 0;

function entry()
  print(_NAME.." entry");
	-- HeadFSM.sm:set_state('headTrack'); -- I need to test if this is useful later to prevent goalie from losing the ball

  t0 = Body.get_time();

  -- set turn direction to last known ball position
  ball = wcm.get_ball();
  if (ball.y > 0) then
    direction = 1;
    mcm.set_walk_isSearching(1);
  else
    direction = -1;
    mcm.set_walk_isSearching(-1);
  end
end

function update()
  local t = Body.get_time();
  ball = wcm.get_ball();
  pose = wcm.get_pose();

  -- search/spin until the ball is found
  vx,vy,va = velgeneration.bodySearchVelocity(vSpin,direction)
  walk.set_velocity(vx, vy, va);

  uPose = vector.new({pose.x,pose.y,pose.a})
	homePose = position.getGoalieHomePose();
  homeRelative = util.pose_relative(homePose, uPose);  
  rHomeRelative = math.sqrt(homeRelative[1]^2 + homeRelative[2]^2);

	-- make sure that the goalie doesn't turn too much if it is in home position
	if rHomeRelative < math.sqrt(thClose[1] ^ 2 + thClose[2] ^ 2) and
    math.abs(pose.a) > turnAngleLimit then
    sidesSearched = sidesSearched + 1;
    if (sidesSearched == 2) then
      return "done";
    end

    print("goalie has searched one side; now turning to other side");
    print("time since start: ", t - t0);
    direction = -direction;
	end

  if (t - ball.t < 0.2) then
    return "ball";
  end
  
  if (t - t0 > timeout) then
    return "timeout";
  end
end

function exit()
  mcm.set_walk_isSearching(0);
end
