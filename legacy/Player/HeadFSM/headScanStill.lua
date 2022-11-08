------------------------------
--NSL Linear two-line head scan
------------------------------

module(..., package.seeall);

require('Body')
require('wcm')
require('mcm')
log = require('log')

pitch0=Config.fsm.headScan.pitch0;
pitchMag=Config.fsm.headScan.pitchMag;
yawMag=Config.fsm.headScan.yawMag;
yawMagTurn = Config.fsm.headScan.yawMagTurn;

pitchTurn0 = Config.fsm.headScan.pitchTurn0;
pitchTurnMag = Config.fsm.headScan.pitchTurnMag;


tScan = Config.fsm.headScan.tScan2 or 3;
tScan = tScan * 4;
--timeout = tScan * 4;
timeout = 120

t0 = 0;
direction = 1;

ballUsed = -1; --initialized to -1, 0 for local, 1 for team

mode = 1;
height = -.25;

function entry()
  print("Head SM:".._NAME.." entry");
  print('running headScanStill');
  wcm.set_ball_t_locked_on(0);

  --Goalie need wider scan
  role = gcm.get_team_role();
  if role==0 then
    yawMag=Config.fsm.headScan.yawMagGoalie;
    mcm.set_walk_isSearching(0);
  else
    yawMag=Config.fsm.headScan.yawMag;
  end

  -- start scan in ball's last known direction
  t0 = Body.get_time();
  ball = wcm.get_ball();
  timeout = tScan * 2;

  yaw_0, pitch_0 = HeadTransform.ikineCam(ball.x, ball.y,0);
  local currentYaw = Body.get_head_position()[1];

  if currentYaw>0 then
    direction = -1;
  else
    direction = 1;
  end
  if pitch_0>pitch0 then
    pitchDir=1;
  else
    pitchDir=-1;
  end
  vcm.set_camera_command(-1); --switch camera
end

function update()
 -- print('updating headscan')
  pitchBias =  mcm.get_headPitchBias();--Robot specific head angle bias

  --Is the robot in bodySearch and spinning?
  isSearching = mcm.get_walk_isSearching();

  local t = Body.get_time();
  -- update head position

  -- Scan left-right and up-down with constant speed

  --[[if isSearching ==0 then --Normal headScan
    local ph = (t-t0)/tScan;
    ph = ph - math.floor(ph);
    if ph<0.0833 then --phase 0 to 0.25
      yaw=-80*math.pi/180 * direction;
      pitch=pitch0-pitchMag*pitchDir+height;
    elseif ph<0.166 then --phase 0.25 to 0.75
      yaw=-40*math.pi/180 * direction;
      pitch=pitch0-pitchMag*pitchDir+height;
    elseif ph<0.25 then --phase 0.25 to 0.75
      yaw=0 * direction;
      pitch=pitch0-pitchMag*pitchDir+height;
    elseif ph<0.333 then --phase 0.25 to 0.75
      yaw=40*math.pi/180 * direction;
      pitch=pitch0-pitchMag*pitchDir+height;
    elseif ph < 0.416 then --phase 0.75 to 1
      yaw=80*math.pi/180 * direction;
      pitch=pitch0+pitchMag*pitchDir+height;
    elseif ph<0.5 then --phase 0.25 to 0.75
      yaw=40*math.pi/180 * direction;
      pitch=pitch0-pitchMag*pitchDir;
    elseif ph<0.583 then --phase 0.25 to 0.75
      yaw=0 * direction;
      pitch=pitch0-pitchMag*pitchDir;
    elseif ph<0.666 then --phase 0.25 to 0.75
      yaw=-40*math.pi/180 * direction;
      pitch=pitch0-pitchMag*pitchDir;
    elseif ph<0.75 then --phase 0.75 to 1
      yaw=-80*math.pi/180 * direction;
      pitch=pitch0-pitchMag*pitchDir+height;
    else
      yaw = 0;
      pitch = 0;
    end --]]

    if isSearching ==0 then --Normal headScan
      local ph = (t-t0)/tScan;
      ph = ph - math.floor(ph);
      if ph<0.125 then --phase 0 to 0.25
        yaw=-80*math.pi/180 * direction;
        pitch=pitch0-pitchMag*pitchDir+height;
      elseif ph<0.25 then --phase 0.25 to 0.75
        yaw=-40*math.pi/180 * direction;
        pitch=pitch0-pitchMag*pitchDir+height;
      elseif ph<0.375 then --phase 0.25 to 0.75
        yaw=0 * direction;
        pitch=pitch0-pitchMag*pitchDir+height;
      elseif ph<0.5 then --phase 0.25 to 0.75
        yaw=40*math.pi/180 * direction;
        pitch=pitch0-pitchMag*pitchDir+height;
      elseif ph < 0.625 then --phase 0.75 to 1
        yaw=80*math.pi/180 * direction;
        pitch=pitch0+pitchMag*pitchDir+height;
      elseif ph<0.75 then --phase 0.25 to 0.75
        yaw=40*math.pi/180 * direction;
        pitch=pitch0-pitchMag*pitchDir;
      elseif ph<0.875 then --phase 0.25 to 0.75
        yaw=0 * direction;
        pitch=pitch0-pitchMag*pitchDir;
      else
        yaw=-40*math.pi/180 * direction;
        pitch=pitch0-pitchMag*pitchDir;
      end

  else --Rotating scan
    timeout = 20.0 * Config.speedFactor; --Longer timeout
    local ph = (t-t0)/tScan * 2;
    ph = ph - math.floor(ph);
    --Look up and down in constant speed
    if ph<0.25 then
      pitch=pitchTurn0+pitchTurnMag*(ph*4);
    elseif ph<0.75 then
      pitch=pitchTurn0+pitchTurnMag*(1-(ph-0.25)*4);
    else
      pitch=pitchTurn0+pitchTurnMag*(-1+(ph-0.75)*4);
    end
    yaw = yawMagTurn * isSearching;
  end

  if math.abs(yaw) > 55 * (math.pi/180) then
    wcm.set_robot_shoulder_covered(2);
  elseif math.abs(yaw) > 35 * (math.pi/180) then
    wcm.set_robot_shoulder_covered(1);
  else
    wcm.set_robot_shoulder_covered(0);
  end
--  print('pitch = '..pitch)
--  print('pitch-pitchBias = '..pitch-pitchBias)
  Body.set_head_command({yaw, pitch-pitchBias});

  local ball = wcm.get_ball();
  if (t - ball.t < 0.1) then
    --if we aren't using team ball then we see the ball
    if wcm.get_robot_use_team_ball() == 0 then
			if ballUsed ~= 0 then
      	print('headScan: new local ball found')
				ballUsed = 0;
			end

			log.debug("Transition: ball");
      return "ball";
    --if we are using team ball we can look towards it if we are moving
    elseif (wcm.get_robot_use_team_ball() == 1 and (role ~= 2 and role ~= 4)) or (vcm.get_ball_detect()==1)then
			if ballUsed ~= 1 then
      	print('headScan: team ball found')
				ballUsed = 1;
			end
      log.debug("Transition: ball");

      return "ball";
    end
  end

  --Otherwise just timeout
  if (t - t0 > timeout) then
    print('headScan timed out')
    log.debug("Transition: timeout", timeout);
    return "timeout";
  end
end

function exit()
end
