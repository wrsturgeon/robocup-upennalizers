-- Test SM for walk kick
-- Not for distribute


module(..., package.seeall);

require('Body')
require('vector')
require('Motion');
require('kick');
require('HeadFSM')
require('Config')
require('wcm')

require('walk');

t0 = 0;
timeout = Config.fsm.bodyWalkKick.timeout;
walkkick_th = 0.14; --Threshold for step-back walkkick for OP
follow = false


function entry()
  print(_NAME.." entry");

  t0 = Body.get_time();
  kick_dir = wcm.get_kick_dir();
  print("KICK DIR:", kick_dir)
  if kick_dir == 1 then --straight walkkick
    -- set kick depending on ball position
    ball = wcm.get_ball();
    print("WalkKick: Ball pos:", ball.x, ball.y);
    if (ball.y > 0) then
      walk.doWalkKickLeft()
    else
      walk.doWalkKickRight()
    end
  elseif kick_dir == 2 then
    walk.doSideKickLeft() --sidekick to left
  else
    walk.doSideKickRight() --sidekick to right
  end
  HeadFSM.sm:set_state('headTrack');
end

function update()
  local t = Body.get_time();
  if kick_dir == 1 and Config.largestep_enable == true then --are we doing stepkick?
    if mcm.get_walk_isStepping() == 0 then
      return "done"
    end
  else
    if (t - t0 > timeout) then 
      return "done"
    end --for walkkick, just wait a bit
  end

  --SJ: should be done in better way?
  if walk.walkKickRequest == 0 and follow == false then
    follow = true;
    HeadFSM.sm:set_state('headKickFollow');
  end
end

function exit()
end