module(..., package.seeall);

require('Body')
require('util')
require('vector')
require('walk')
require('wcm')
require('position')
require('gcm')

role = -1;
t0 = 0;
timeout = 7.0;
tLost = 3.0;

mixedGame = Config.fsm.mixedGame;

function entry()
  t0 = Body.get_time();
	mcm.set_walk_isSearching(0);
  HeadFSM.sm:set_state('headScan');
  role = gcm.get_team_role()
  print("Body Still Entry")
end


function update()
  
  local t = Body.get_time();
  ball = wcm.get_ball();

  --if nobody knows where ball is then search for it, otherwise turn towards ball
  if (t - ball.t > tLost) then 
    print('BodyStillBallLost')
    return "ballLost"
  elseif mixedGame then
    walk.stop();
  else
    ballA = util.mod_angle(math.atan2(ball.y, ball.x));
    if math.abs(ballA) > 30*math.pi/180 then
      walk.set_velocity(0, 0, 0.5*ballA);
    else
      walk.stop();
    end
  end
  
  --Timeout if we have been here for a while
  if (t - t0 > timeout) then
    print('BodyStillTimeout')
    return "timeout"  
  end
  
  --if we changed roles then we probably need to do something else
  if role ~= gcm.get_team_role() then 
    print('BodyStillRoleChange from ', role, "to ", gcm.get_team_role()) 
    return "roleChange"
  end
  
end


function exit()
    walk.start();
end

