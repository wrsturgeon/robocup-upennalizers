module(..., package.seeall);

require('Body')
require('vector')
require('Motion')
require('HeadFSM')
require('Config')
require('wcm')
require('walk')
require('gcm')


--ball position checking params
DribbleTargetFront={0.2,0.04};
DribbleTh={0.1,0.1};

tFollowDelay = 0.5;
DribbleSpeed = 0.06;

dribbleBoundsX = {-2,1.5};

t0 = 0;
tStart = 0;
timeout = 10.0;
phase=0;

function entry()
  print(_NAME.." entry");
  t0 = Body.get_time();
  phase=0;   
end


function update()
  t = Body.get_time();
  local role = gcm.get_team_role();
  local pose = wcm.get_pose();

  if not walk.active then 
     	print("bodyDribble escape");
     	return "done";
  end

--Dont dribble if we are goalie or too close to our goal or close to opponentes goal
 -- if role == 0 or 
--	 pose.x < dribbleBoundsX[1] or 
 --	 pose.x > dribbleBoundsX[2] then
--		print('Kick instead of dribble');
--		return "kick";
 -- end

  if (t - t0 > timeout) then
    print("bodyDribble timeout")
    return "timeout";
  end

  if phase==0 and walk.active then
    if check_ball_pos() then
       phase=1;
       tStart=t;
       walk.set_velocity(DribbleSpeed,0,0);
    else
       print("bodyDribble: reposition")
       return "reposition";
    end

  elseif phase==1 then
    if t-tStart > tFollowDelay then
		if check_ball_pos() then
			phase = 0;
		else
      		return "done"
		end
    end
  end
end

function check_ball_pos()
  ball = wcm.get_ball();

  kick_dir=wcm.get_kick_dir();

  if kick_dir==1 then
      --Dribble forward
      xTarget,yTarget=DribbleTargetFront[1],DribbleTargetFront[2];    
  else --cant dribble to the side
    return false
  end

--[[  print("Kick dir:",kick_dir)
  print("Ball position: ",ball.x,ball.y)
  print("Ball target:",xTarget,yTarget)]]--

  ballErr = {ball.x-xTarget,ball.y-yTarget};
 --[[ print("ball error:",unpack(ballErr))
  print("Ball pos threshold:",unpack(DribbleTh))
  print("Ball seen:",t-ball.t," sec ago");]]--

  if ballErr[1]<DribbleTh[1] and --We don't care if ball is too close
    math.abs(ballErr[2])<DribbleTh[2] and
    (t - ball.t <0.5) then
    return true;
  else
    return false;
  end  
end

function exit()
end
