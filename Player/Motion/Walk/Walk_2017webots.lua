--locomotion for Robocup 2017 (with adaptation to turf)
---Author of correspondence for locomotion 2017:
-- Xiang Deng, dxiang@seas.upenn.edu
---Acknoledgements to: previous ZMP framework from SJ YI et.al, walk_2015.lua
module(..., package.seeall);

-- require "zhelpers"
-- local zmq = require "lzmq"
--
-- -- Prepare our context and publisher
-- local context = zmq.context()
-- local publisher, err = context:socket{zmq.PUB, bind = "tcp://*:5564"}
-- zassert(publisher, err)
-- local subscriber, err = context:socket{zmq.SUB,
-- subscribe = "control_msg";
-- connect = "tcp://192.168.123.99:5563";
-- }
-- zassert(subscriber, err)
-- print('lmzq setup',zmq);

function rounddeci(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end
function mysplit(inputstr, sep)
  -- http://stackoverflow.com/questions/1426954/split-string-in-lua
  if sep == nil then
    sep = "%s"
  end
  local t={} ; i=1
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    t[i] = str
    i = i + 1
  end
  return t
end
tUpdate = unix.time();

dlt0=0.02;
useremote1=true;
dontmove=false;
usetoesupport=false;
leftkick=false;
kickcommandpause=false;
unlock_kick=0;
uLeftoff = vector.new({0, 0, 0});
uRightoff = vector.new({0, 0, 0});
uTorsooff=vector.new({0, 0, 0});
-- =================================================

require('Body')
require('Kinematics')
require('Config');
require('vector')
require('mcm')
require('unix')
require('util')
require('Body')

-----------------------------
local matrix = require('matrix');
--------------------------------

-- Walk Parameters
-- Stance and velocity limit values
stanceLimitX=Config.walk.stanceLimitX or {-0.10 , 0.10};
stanceLimitY=Config.walk.stanceLimitY or {0.09 , 0.20};
stanceLimitY={2*Config.walk.footY - 2*Config.walk.supportY,0.20} --needed to prevent from tStep getting too small
stanceLimitA=Config.walk.stanceLimitA or {-0*math.pi/180, 40*math.pi/180};
velLimitX = Config.walk.velLimitX or {-.06, .1};
velLimitY = Config.walk.velLimitY or {-.06, .06};
velLimitA = Config.walk.velLimitA or {-.4, .4};
velDelta = Config.walk.velDelta or {.03,.015,.15};
vaFactor = Config.walk.velLimitA[2] or 0.6;
velXHigh = Config.walk.velXHigh or 0.06;
velDeltaXHigh = Config.walk.velDeltaXHigh or 0.01;

--Toe/heel overlap checking values
footSizeX = Config.walk.footSizeX or {-0.05,0.05};
stanceLimitMarginY = Config.walk.stanceLimitMarginY or 0.015;
stanceLimitY2= 2* Config.walk.footY-stanceLimitMarginY;

--Compensation parameters
ankleMod = Config.walk.ankleMod or {0,0};
spreadComp = Config.walk.spreadComp or 0;
turnCompThreshold = Config.walk.turnCompThreshold or 0;
turnComp = Config.walk.turnComp or 0;

--Gyro stabilization parameters
ankleImuParamX = Config.walk.ankleImuParamX;
ankleImuParamY = Config.walk.ankleImuParamY;
kneeImuParamX = Config.walk.kneeImuParamX;
hipImuParamY = Config.walk.hipImuParamY;

--Support bias parameters to reduce backlash-based instability
velFastForward = Config.walk.velFastForward or 0.06;
velFastTurn = Config.walk.velFastTurn or 0.2;
supportFront = Config.walk.supportFront or 0;
supportFront2 = Config.walk.supportFront2 or 0;
supportBack = Config.walk.supportBack or 0;
supportSideX = Config.walk.supportSideX or 0;
supportSideY = Config.walk.supportSideY or 0;
supportTurn = Config.walk.supportTurn or 0;
frontComp = Config.walk.frontComp or 0.003;
AccelComp = Config.walk.AccelComp or 0.003;

uFoot = vector.zeros(3)

--Initial body swing
supportModYInitial = Config.walk.supportModYInitial or 0

--WalkKick parameters
walkKickDef = Config.kick.walkKickDef;
walkKickPh = Config.kick.walkKickPh;

--------------------------------
-- walkKickPh=0.5;
----------------------------------
--Use obstacle stop?
obscheck = Config.walk.obscheck or false

--Dirty part
function load_default_param_values()
  local p={}

  p.bodyTilt = Config.walk.bodyTilt or 0
  p.tStep = Config.walk.tStep
  p.tStep0 = Config.walk.tStep
  p.bodyHeight = Config.walk.bodyHeight
  --footX = mcm.get_footX();
  p.footY = Config.walk.footY
  p.supportX = Config.walk.supportX
  p.supportY = Config.walk.supportY
  p.tZmp = Config.walk.tZmp
  --
  -- p.tStep=p.tStep*4;
  -- p .tStep0=p .tStep0*4;
  -- p.tZmp=p.tZmp*4;

  -- p.stepHeight0 = Config.walk.stepHeight
  -- p.stepHeight = Config.walk.stepHeight

  steph=0.03;
  -- steph=0.015;
  p.stepHeight0=steph;
  p.stepHeight=steph;

  p.phSingleRatio = Config.walk.phSingleRatio or 0.04
  p.hardnessSupport = Config.walk.hardnessSupport or 0.75
  p.hardnessSwing = Config.walk.hardnessSwing or 0.5
  p.hipRollCompensation = Config.walk.hipRollCompensation;
  p.zmpparam={aXP=0,aXN=0, aYP=0, aYN=0}
  p.zmp_type = 1 --0 for square zmp
  return p
end

cp=load_default_param_values()
np=load_default_param_values()

----------------------------------------------------------
-- Walk state variables
----------------------------------------------------------

--u means for the world coordinate, origin is in the middle of two feet
uTorso = vector.new({Config.walk.supportX, 0, 0});
uLeft = vector.new({0, Config.walk.footY, 0});
uRight = vector.new({0, -Config.walk.footY, 0});
velCurrent, velCommand,velDiff = vector.new({0,0,0}),vector.new({0,0,0}),vector.new({0,0,0})

--Gyro stabilization variables
ankleShift,kneeShift,hipShift,toeTipCompensation = vector.new({0,0}),0,vector.new({0,0}),0

active = true;
started = false;
iStep0,iStep = -1,0
tLastStep = Body.get_time()

stopRequest = 2;
canWalkKick = true; --Can we do walkkick with this walk code?
walkKickRequest = 0;
walkKick = walkKickDef["FrontLeft"];
current_step_type = 0;
initial_step=2;
ph,phSingle = 0,0

--emergency stop handling
is_stopped = false
stop_threshold = {10*math.pi/180,35*math.pi/180}
tStopStart = 0
tStopDuration = 2.0
supportLeg=0;
----------------------------------------------------------
-- End initialization
----------------------------------------------------------
local max_unstable_factor=0
file = io.open("walklog.txt", "w+");

function writedatatofile_headers()

  local jointNames = { "HeadYaw", "HeadPitch",
    "LShoulderPitch", "LShoulderRoll",
    "LElbowYaw", "LElbowRoll",
    "LHipYawPitch", "LHipRoll", "LHipPitch",
    "LKneePitch", "LAnklePitch", "LAnkleRoll",
    "RHipYawPitch", "RHipRoll", "RHipPitch",
    "RKneePitch", "RAnklePitch", "RAnkleRoll",
    "RShoulderPitch", "RShoulderRoll",
    "RElbowYaw", "RElbowRoll","lastZMPL","ZMPL","ZMPFl","ZMPFr","pressureL","pressureR","supportLeg"} ;
  local jointstr="jointNames";
  for i=1,#jointNames do
    jointstr=jointstr..","..jointNames[i];
  end
  --file:write( jointstr, "\n")

end
function writedatatofile_joints()
  -- local file = io.open("walklog.txt", "w")
  local qs_head=Body.get_head_position();
  local qs_lleg=Body.get_lleg_position();
  local qs_rleg=Body.get_rleg_position();
  local qs_larm=Body.get_larm_position();
  local qs_rarm=Body.get_rarm_position();
  local jointstr=""..qs_head[1];
  for i=2,#qs_head do
    jointstr=jointstr..","..qs_head[i];
  end
  for i=1,#qs_larm do
    jointstr=jointstr..","..qs_larm[i];
  end
  for i=1,#qs_lleg do
    jointstr=jointstr..","..qs_lleg[i];
  end

  for i=1,#qs_rleg do
    jointstr=jointstr..","..qs_rleg[i];
  end
  for i=1,#qs_rarm do
    jointstr=jointstr..","..qs_rarm[i];
  end
  jointstr=jointstr..","..lastZMPL
  jointstr=jointstr..","..ZMPL;
  jointstr=jointstr..","..ZMPFl;
  jointstr=jointstr..","..ZMPFr;
  jointstr=jointstr..","..pressureL;
  jointstr=jointstr..","..pressureR;
  jointstr=jointstr..","..supportLeg-0.5;
  file:write( jointstr, "\n")
  -- file:close()
end
writedatatofile_headers();
function entry()

  print ("Motion: Walk entry")
  stance_reset();
  -- lfsr=Body.get_sensor_fsrLeft();
  -- print('lfsr',unpack(lfsr))
  --Place arms in appropriate position at sides
  --[[ Body.set_larm_command(Config.walk.qLArm)
  Body.set_rarm_command(Config.walk.qRArm)
  Body.set_larm_hardness(Config.walk.hardnessArm or 0.2)
  Body.set_rarm_hardness(Config.walk.hardnessArm or 0.2);--]]
  walkKickRequest = 0;
  max_unstable_factor=0;
end

-----------------------------------------------------
usearm=true;
walk_dir_compens=0.03;
vel_backwds=-0.005;
vel_zero_fwoff=0.01;
prev_pitch=0;
vel_pitch={};
vel_pitch.y_hat=0;
vel_pitch.kp=1;
vel_pitch.ki=0.01;
vel_pitch.error_acc=0;
prev_roll=0;
vel_roll={};
vel_roll.y_hat=0;
vel_roll.kp=1;
vel_roll.ki=0.01;
vel_roll.error_acc=0;
t_vel_prev=Body.get_time();
isrotating=false;
t_kickstart=0;
kickrequested=false;

vels_ql={};
for i=1,6 do
  vel_qi={};
  vel_qi.y_hat=0;
  vel_qi.kp=1;
  vel_qi.ki=0.01;
  vel_qi.error_acc=0;
  vels_ql[i]=vel_qi;
end
vels_qr={};
for i=1,6 do
  vel_qi={};
  vel_qi.y_hat=0;
  vel_qi.kp=1;
  vel_qi.ki=0.01;
  vel_qi.error_acc=0;
  vels_qr[i]=vel_qi;
end
qds_l={n=6};
qds_r={n=6};
qLegs_prev={};
isnewstep=false;

function vel_est(y,Ts,vel_param)
  error=y-vel_param.y_hat;
  vel_param.error_acc=vel_param.error_acc+error*Ts;
  v_est=vel_param.kp*error+vel_param.ki*vel_param.error_acc;
  vel_param.y_hat=vel_param.y_hat+v_est*Ts;
  return v_est;
end
function vel_est_many(ys,Ts,vels_param)--also Xiang
  vs_est={};
  for i=1,table.getn(vels_param) do
    error=ys[i]-vels_param[i].y_hat;
    vels_param[i].error_acc=vels_param[i].error_acc+error*Ts;
    vs_est[i]=vels_param[i].kp*error+vels_param[i].ki*vels_param[i].error_acc;
    vels_param[i].y_hat=vels_param[i].y_hat+vs_est[i]*Ts;
  end
  return vs_est;
end

fsLfl=0;
fsLfr=0;
fsLrl=0;
fsLrr=0;

fsRfl=0;
fsRfr=0;
fsRrl=0;
fsRrr=0;
lastZMPL=0;
ZMPL=0;

ZMPFl=0;
ZMPFr=0;

cnter=0;
pressureL=0;
pressureR=0;
function computeZMPfromSensor()
  lfsr=Body.get_sensor_fsrLeft();
  rfsr=Body.get_sensor_fsrRight();

  local temp = lfsr[1]; if(fsLfl<temp and fsLfl<5.0) then fsLfl = temp;end
  temp = lfsr[3]; if(fsLfr<temp and fsLfr<5.0) then fsLfr = temp; end
  temp = lfsr[2]; if(fsLrl<temp and fsLrl<5.0) then fsLrl = temp;end
  temp = lfsr[4]; if(fsLrr<temp and fsLrr<5.0) then fsLrr = temp; end

  temp = rfsr[1]; if(fsRfl<temp and fsRfl<5.0) then fsRfl = temp; end
  temp = rfsr[3]; if(fsRfr<temp and fsRfr<5.0) then fsRfr = temp; end
  temp = rfsr[2]; if(fsRrl<temp and fsRrl<5.0) then fsRrl = temp; end
  temp = rfsr[4]; if(fsRrr<temp and fsRrr<5.0) then fsRrr = temp; end
  lastZMPL = ZMPL;
  ZMPL = 0;

  pressureL =
    lfsr[1]/fsLfl
    + lfsr[3]/fsLfr
    + lfsr[2]/fsLrl
    + lfsr[4]/fsLrr;
  pressureR =
    rfsr[1]/fsRfl
    + rfsr[3]/fsRfr
    + rfsr[2]/fsRrl
    + rfsr[4]/fsRrr;
  local totalPressure = pressureL + pressureR;
  if (math.abs(totalPressure) > 0.000001) then
    ZMPL =
      ( .080 * lfsr[1]/fsLfl
      + .030 * lfsr[3]/fsLfr
      + .080 * lfsr[2]/fsLrl
      + .030 * lfsr[4]/fsLrr
      - .030 * rfsr[1]/fsRfl
      - .080 * rfsr[3]/fsRfr
      - .030 * rfsr[2]/fsRrl
      - .080 * rfsr[4]/fsRrr) / totalPressure;
  end


  ZMPFl = 0; --in left foot frame
  ZMPFr = 0; --in right foot frame
  if (math.abs(pressureL) > 0.000001) then
    ZMPFl =
      ( .070 * lfsr[1]/fsLfl
      + .070 * lfsr[3]/fsLfr
      - .030 * lfsr[2]/fsLrl
      - .030 * lfsr[4]/fsLrr ) / pressureL;
  end
  if (math.abs(pressureR) > 0.000001) then
    ZMPFr =
      (
      .070 * rfsr[1]/fsRfl
      + .070 * rfsr[3]/fsRfr
      - .030 * rfsr[2]/fsRrl
      - .030 * rfsr[4]/fsRrr) / pressureR;
  end
end



function normalloop()
  cnter=cnter+1;
  t = Body.get_time()
  if cnter % 20==0 then
  -- writedatatofile_joints();
  end
  imuAngle = Body.get_sensor_imuAngle();
  -- print("imuAngle:",imuAngle[1]*180/math.pi,imuAngle[2]*180/math.pi)
  -- computeZMPfromSensor();
  if cnter % 50 ==0 then
  -- print ('ZMPL ', ZMPL,'ZMPFl ', ZMPFl, 'ZMPFr ', ZMPFr)
  end

  local unstable_factor = math.max (
    math.abs(imuAngle[1]) / stop_threshold[1],
    math.abs(imuAngle[2]) / stop_threshold[2]
  )
  max_unstable_factor = math.max(unstable_factor, max_unstable_factor)

  --start emergency stop

  --end emergency stop
  if is_stopped and t>tStopStart+tStopDuration then
    is_stopped = false
    start()
    return
  end

  footX = mcm.get_footX()

  --for obstacle detection
  if mcm.get_us_frontobs() == 1 and obscheck == true then
    vy, va = velCurrent[2],velCurrent[3]
    set_velocity(-0.02, 0, 0)
    print("obstacle!!!!!")
  end

  --Don't run update if the robot is sitting or standing
  if vcm.get_camera_bodyHeight()<cp.bodyHeight-0.01 then return end

  if (not active) then mcm.set_walk_isMoving(0);update_still() return end

  mcm.set_walk_isMoving(1)

  if (not started) then started=true;tLastStep = Body.get_time() end

  --step phase factor, should between 0 to 1
  ph = (t-tLastStep)/cp.tStep

  if (ph>0.75 and lastZMPL*ZMPL<0 ) then
  -- print("here --------")
  end

  if ph>1 or (ph>0.75 and lastZMPL*ZMPL<0 ) then
    iStep=iStep+1
    ph=ph-math.floor(ph)
    tLastStep=tLastStep+cp.tStep
  end

  --Stop when stopping sequence is done
  if (iStep > iStep0) and(stopRequest==2) then
    stopRequest = 0
    active = false
    return "stop"
  end

  -- local imuAngle = Body.get_sensor_imuAngle();
  local curt=Body.get_time();
  local deltat=curt-t_vel_prev;
  -- print('curt',curt,'\n')
  if deltat>0.01 then
    t_vel_prev=curt;
    vest_pitch=vel_est(imuAngle[2],deltat,vel_pitch);
    vest_roll=vel_est(imuAngle[1],deltat,vel_roll);
    local qs_lleg=Body.get_lleg_position();
    local qs_rleg=Body.get_rleg_position();
    qds_l=vel_est_many(qs_lleg,deltat,vels_ql);
    qds_r=vel_est_many(qs_rleg,deltat,vels_qr)
  end
  ----------------
  -- New step
  if (iStep > iStep0) then
    update_velocity();
    iStep0 = iStep;
    local tStep_next = calculate_swap()

    supportLeg = iStep % 2; -- 0 for left support, 1 for right support
    uLeft1,uRight1,uTorso1 = uLeft2,uRight2,uTorso2

    --Switch walk params
    cp = np
    np = load_default_param_values()
    -- np.stepHeight=0.016;---- *<<<<<<PARAM>>>>>/
    if walkKickRequest==0 then
      np.tStep0 = tStep_next
      np.tStep = tStep_next
    end

    uLRFootOffset = vector.new({0,cp.footY,0})
    supportMod = {0,0}; --Support Point modulation for walkkick
    shiftFactor = 0.5; --How much should we shift final Torso pose?
    -- check_walkkick();
    if  walkKickRequest>0 or kickcommandpause then
      print('kick start \n')
      walkKickRequest=0;
      current_step_type=0;

      if leftkick then
        if supportLeg==1  then
          unlock_kick=2;
          kickcommandpause=false;
        else
          kickcommandpause=true;
        end
      else
        if supportLeg==0  then
          unlock_kick=2;
          kickcommandpause=false;
        else
          kickcommandpause=true;
        end
      end
    end
    -- if unlock_kick >0  then
    --   local capx=math.sqrt(0.3/9.8)*0.3*imuAngle[2];
    --   -- print('vest_pitch',vest_pitch,'capx',capx,'+capx/cp.tStep0', capx/cp.tStep0,'\n')
    --   if unlock_kick<2 or math.abs(imuAngle[2]) >0.2 then
    --     velCurrent[1]=capx/cp.tStep0;
    --   else
    --     velCurrent[1]=0.15
    --   end
    --   velCurrent[3]=0;
    -- end
    if unlock_kick>0 then
      unlock_kick=unlock_kick-1;

    end
    ----------------------------------
    if walkKickRequest==0 then
      if (stopRequest==1) then --Final step
        stopRequest=2
        velCurrent,velCommand=vector.new({0,0,0}),vector.new({0,0,0}) ;
        if supportLeg == 0 then uRight2 = util.pose_global(-2*uLRFootOffset, uLeft1) --LS
        else uLeft2 = util.pose_global(2*uLRFootOffset, uRight1) --RS
        end
      else --Normal walk, advance steps
        cp.tStep=cp.tStep0
        if supportLeg == 0 then
          uRight2 = step_right_destination(velCurrent, uLeft1, uRight1) --LS
        else
          uLeft2 = step_left_destination(velCurrent, uLeft1, uRight1) --RS
        end
        --Velocity-based support point modulation
        toeTipCompensation = 0;
        if velDiff[1]>0 then supportMod[1] = supportFront2 --Accelerating to front
        elseif velCurrent[1]>velFastForward then supportMod[1] = supportFront;toeTipCompensation = ankleMod[1]
        elseif velCurrent[1]<0 then supportMod[1] = supportBack
        elseif math.abs(velCurrent[3])>velFastTurn then supportMod[1] = supportTurn
        else
          if velCurrent[2]>0.015 then supportMod[1],supportMod[2] = supportSideX,supportSideY
          elseif velCurrent[2]<-0.015 then supportMod[1],supportMod[2] = supportSideX,-supportSideY
          end
        end
      end
    end

    uTorso2 = step_torso(uLeft2, uRight2,shiftFactor)

    --Adjustable initial step body swing
    if initial_step>0 then
      if supportLeg == 0 then supportMod[2]=supportModYInitial --LS
      else supportMod[2]=-supportModYInitial end--RS
    end

    --Apply velocity-based support point modulation for uSupport
    if supportLeg == 0 then --LS
      local uLeftTorso = util.pose_relative(uLeft1,uTorso1);
      local uTorsoModded = util.pose_global(vector.new({supportMod[1],supportMod[2],0}),uTorso)
      local uLeftModded = util.pose_global (uLeftTorso,uTorsoModded);
      uSupport = util.pose_global({cp.supportX, cp.supportY, 0},uLeftModded)

      Body.set_lleg_hardness(cp.hardnessSupport);
      Body.set_rleg_hardness(cp.hardnessSwing);

    else --RS
      local uRightTorso = util.pose_relative(uRight1,uTorso1);
      local uTorsoModded = util.pose_global(vector.new({supportMod[1],supportMod[2],0}),uTorso)
      local uRightModded = util.pose_global (uRightTorso,uTorsoModded);
      uSupport = util.pose_global({cp.supportX, -cp.supportY, 0}, uRightModded)

      Body.set_rleg_hardness(cp.hardnessSupport);
      Body.set_lleg_hardness(cp.hardnessSwing);

    end
    calculate_zmp_param(uSupport,uTorso1,uTorso2,cp)
    max_unstable_factor=0
    isnewstep=true;
  else
    isnewstep=false;
  end --End new step

  xFoot, zFoot = foot_phase(ph)

  if initial_step>0 then zFoot=0; end --Don't lift foot at initial step
  zLeft, zRight = 0,0
  if supportLeg == 0 then -- Left support
    if current_step_type>1 then --walkkick
      if xFoot<walkKickPh then uRight = util.se2_interpolate(math.sin(xFoot/walkKickPh*math.pi/4), uRight1, uRight15)
      else uRight = util.se2_interpolate(xFoot/walkKickPh-1, uRight15, uRight2) end
  else uRight = util.se2_interpolate(xFoot, uRight1, uRight2) end
  zRight = cp.stepHeight*zFoot
  else -- Right support

    if current_step_type>1 then --walkkick
      -- print('uLeft15',uLeft15,'walkKickPh','xFoot',xFoot,walkKickPh,'\n')
      local vff=math.sin(xFoot/walkKickPh*math.pi/4);
      -- vff=xFoot/walkKickPh;
      if xFoot<walkKickPh then uLeft = util.se2_interpolate(vff, uLeft1, uLeft15)
      else uLeft = util.se2_interpolate(xFoot/walkKickPh-1, uLeft15, uLeft2) end
  else uLeft = util.se2_interpolate(xFoot, uLeft1, uLeft2) end
  zLeft = cp.stepHeight*zFoot
  end

  --Turning
  local turnCompX=0;
  if math.abs(velCurrent[3])>turnCompThreshold and velCurrent[1]>-0.01 then turnCompX = turnComp end

  --Walking front
  local frontCompX = 0
  if velCurrent[1]>0.04 then frontCompX = frontComp end
  if velDiff[1]>0.02 then frontCompX = frontCompX + AccelComp end

  uTorso = zmp_com(ph,cp)
  uTorso[3] = 0.5*(uLeft[3]+uRight[3]) --nao leg joint is interdependent
  local zeromovecomp=0;

  uTorsoActual = util.pose_global(vector.new({-footX+frontCompX+turnCompX+zeromovecomp,0,0}),uTorso)


  -- if unlock_kick>0 and ph<0.3  then
  --   if supportLeg==0 then
  --     zRight=(cp.stepHeight+0.02)*zFoot+0.01;
  --   else
  --     zLeft=(cp.stepHeight+0.2)*zFoot+0.01;
  --
  --   end
  -- end



  pLLeg = vector.new({uLeft[1], uLeft[2], zLeft, 0,0,uLeft[3]});
  pRLeg = vector.new({uRight[1], uRight[2], zRight, 0,0,uRight[3]})
  pTorso = vector.new({uTorsoActual[1], uTorsoActual[2], cp.bodyHeight, 0,cp.bodyTilt,uTorsoActual[3]});
  local ph1Single,ph2Single = cp.phSingleRatio/2,1-cp.phSingleRatio/2
  phSingle = math.min(math.max(ph-ph1Single, 0)/(ph2Single-ph1Single),1);


  if  unlock_kick>0 then

    -- pTorso[1]=pTorso[1]+0.0
    -- pTorso[3]=pTorso[3]-0.01
    -- pTorso[4]=pTorso[4]+0.01;
    pLLeg = vector.new({0, cp.footY,zLeft, 0,0,0});
    pRLeg = vector.new({0, -cp.footY, zRight, 0,0,0})
    pTorso = vector.new({0, 0, cp.bodyHeight , 0,cp.bodyTilt ,0});

    if supportLeg==0 and not leftkick then
      local forwardL=pRLeg[1];
      local heightL=pRLeg[3];
      local forwardSide=0.2;
      local factor=3;

      if (phSingle > 0.03*factor and phSingle <= 0.09*factor) then -- first, move foot forward
        local numSteps = 0.06;
        local firstStep = 0.04*factor;
        forwardL = (forwardSide)*((phSingle-firstStep+0.01)/numSteps) + forwardL;
        heightL= 0.05
        pTorso[4]=0.08;
        -- pTorso[5]=0.08;
      elseif (phSingle > 0.09*factor and phSingle <= 0.15*factor) then
        forwardL = forwardSide;
        heightL = 0.02
        pTorso[4]=0.05;
        -- pTorso[5]=0.02;
      elseif (phSingle > 0.15*factor and phSingle <= 0.18*factor) then -- move foot back at the end
        local numSteps = 0.03;
        local firstStep = 0.16*factor;
        forwardL = forwardL + (forwardSide*(1-((phSingle-firstStep+0.01)/numSteps)));
        heightL=pRLeg[3];
        pTorso[4]=0.03;
      end
      print('forwardL',forwardL,'heightL',heightL,'phSingle',phSingle)
      pRLeg[1]=forwardL
      pLLeg[1]=pLLeg[1]-forwardL/9 --  to compensate friction
      pRLeg[3]=heightL
      pLLeg[3]=-heightL
      pTorso[1]=pTorso[1]+forwardL/2
    elseif supportLeg==1 and leftkick then
      local forwardL=pLLeg[1];
      local heightL=pLLeg[3];
      local forwardSide=0.2;
      local factor=3;

      if (phSingle > 0.03*factor and phSingle <= 0.09*factor) then -- first, move foot forward
        local numSteps = 0.06;
        local firstStep = 0.04*factor;
        forwardL = (forwardSide)*((phSingle-firstStep+0.01)/numSteps) + forwardL;
        heightL= 0.04
        pTorso[3]=cp.bodyHeight-0.03;
        pTorso[4]=-0.08;
      elseif (phSingle > 0.09*factor and phSingle <= 0.15*factor) then
        forwardL = forwardSide;
        heightL = 0.02
        pTorso[4]=-0.05;
      elseif (phSingle > 0.15*factor and phSingle <= 0.18*factor) then -- move foot back at the end
        local numSteps = 0.03;
        local firstStep = 0.16*factor;
        forwardL = forwardL + (forwardSide*(1-((phSingle-firstStep+0.01)/numSteps)));
        heightL=0.01;
      end
      print('forwardL',forwardL,'heightL',heightL,'phSingle',phSingle)
      pLLeg[1]=forwardL
      pRLeg[1]=pRLeg[1]-forwardL/9 --  to compensate friction
      pLLeg[3]=heightL
      pRLeg[3]=-heightL
      pTorso[1]=pTorso[1]+forwardL/2
    end
  end

  qLegs = Kinematics.inverse_legs(pLLeg, pRLeg, pTorso, supportLeg);

  motion_legs(qLegs);

  if usearm then
    local qLArm_to={};
    local qRArm_to={};
    local multiplier=1;
    if hasbackward then
      multiplier=-1;
    end
    for i=1,1 do
      if supportLeg==0 then
        qLArm_to[i] = multiplier*-0.04*math.cos(phSingle*math.pi-math.pi/2);
        qRArm_to[i] = multiplier*0.01*math.cos(phSingle*math.pi-math.pi/2) ;
      else
        qLArm_to[i] = multiplier*0.01*math.cos(phSingle*math.pi-math.pi/2);
        qRArm_to[i] = multiplier*-0.04*math.cos(phSingle*math.pi-math.pi/2) ;
      end
    end

    for i=3,4 do
      qLArm_to[i]=0;
      qRArm_to[i]=0;
    end
    qLArm_to[1]= qLArm_to[1]+ math.pi/2;
    qRArm_to[1]= qRArm_to[1]+ math.pi/2 ;
    qLArm_to[2]=0.2;
    qRArm_to[2]=-0.2;
    qRArm_to[4]=0.2;
    qLArm_to[4]=-0.2;
    -- print(unpack(qLArm_to));
    -- print(unpack(qRArm_to));
    Body.set_larm_command(qLArm_to);
    Body.set_rarm_command(qRArm_to);
    Body.set_larm_hardness(0.1);
    Body.set_rarm_hardness(0.1);
  end

  uFoot = util.se2_interpolate(.5, uLeft+uLeftoff, uRight+uRightoff);
-- print ("velCommand",unpack(velCommand))
-- print ("velCurrent",unpack(velCurrent))

end
function update()
  t = unix.time();
  deltaT=t-tUpdate;
  if deltaT>dlt0 then
    tUpdate=t;
  end
  if false then
    testnewkick();
  else
    normalloop();
  end
end

function check_walkkick()
  --Walkkick def:
  --tStep stepType supportFoot stepHeight bodyPosMod footPos1 footPos2

  walkKickRequest=0; --- TODO disable kick for now


  if walkKickRequest==0 then return end
  if walkKickRequest>0 and walkKickRequest>#walkKick then
    print("NEWNEWNEWKICK: WALKKICK DONE");
    walkKickRequest = 0
    cp.tStep = cp.tStep0
    cp.stepHeight = cp.stepHeight0
    current_step_type=0
    velCurrent,velCommand=vector.new({0,0,0}),vector.new({0,0,0})
    return
  end

  if walkKickRequest==1 then
    --Check current supporLeg and feet positions
    --and advance steps until ready
    uFootErr = util.pose_relative(uLeft1,util.pose_global(2*uLRFootOffset,uRight1))
    if supportLeg~=walkKick[1][3] or math.abs(uFootErr[1])>0.02
      or math.abs(uFootErr[2])>0.01 or math.abs(uFootErr[3])>10*math.pi/180 then
      if supportLeg == 0 then uRight2 = util.pose_global( -2*uLRFootOffset, uLeft1)
      else uLeft2 = util.pose_global( 2*uLRFootOffset, uRight1) end
      return
    end
  end
  -- print("NEWNEWNEWKICK: WALKKICK, count",walkKickRequest);

  cp.tStep = walkKick[walkKickRequest][1];
  current_step_type = walkKick[walkKickRequest][2];
  supportLeg = walkKick[walkKickRequest][3];
  cp.stepHeight = walkKick[walkKickRequest][4];
  supportMod = walkKick[walkKickRequest][5];
  shiftFactor = walkKick[walkKickRequest][6];

  if #walkKick[walkKickRequest] <=7 then
    footPos1 = walkKick[walkKickRequest][7];
    print('footPos1')
    for i=1,3 do
      print(footPos1[i]);
    end
    print('\n')
    if supportLeg == 0 then -- TODO: look at uLRFootOffset for use here
      uRight2 = util.pose_global({footPos1[1],footPos1[2]-2*cp.footY,footPos1[3]},uLeft1)
    else
      uLeft2 = util.pose_global({footPos1[1],footPos1[2]+2*cp.footY,footPos1[3]},uRight1)
    end
  else
    footPos1,footPos2 = walkKick[walkKickRequest][7],walkKick[walkKickRequest][8]
    if supportLeg == 0 then
      uRight15 = util.pose_global({footPos1[1],footPos1[2]-2*cp.footY,footPos1[3]},uLeft1)
      uRight2 = util.pose_global({footPos2[1],footPos2[2]-2*cp.footY,footPos2[3]},uLeft1)
    else
      uLeft15 = util.pose_global({footPos1[1],footPos1[2]+2*cp.footY,footPos1[3]},uRight1)
      uLeft2 = util.pose_global({footPos2[1],footPos2[2]+2*cp.footY,footPos2[3]},uRight1)
    end
  end
  walkKickRequest = walkKickRequest + 1;
end

function update_still()
  uTorso = step_torso(uLeft, uRight,0.5);
  uTorsoActual = util.pose_global(vector.new({-footX,0,0}), uTorso);
  pLLeg = vector.new({uLeft[1], uLeft[2], 0, 0,0,uLeft[3]});
  pRLeg = vector.new({uRight[1], uRight[2], 0, 0,0,uRight[3]})
  pTorso = vector.new({uTorsoActual[1], uTorsoActual[2], cp.bodyHeight, 0,cp.bodyTilt,uTorsoActual[3]});
  qLegs = Kinematics.inverse_legs(pLLeg, pRLeg, pTorso, supportLeg);

  Body.set_lleg_hardness(cp.hardnessSupport);
  Body.set_rleg_hardness(cp.hardnessSwing);

  motion_legs(qLegs,true);
end

function motion_legs(qLegs,gyro_off)
  phComp = math.min(1, phSingle/.1, (1-phSingle)/.1);

  --Ankle stabilization using gyro feedback
  imuGyr = Body.get_sensor_imuGyrRPY();
  gyro_roll0,gyro_pitch0=imuGyr[1],imuGyr[2]
  if gyro_off then gyro_roll0,gyro_pitch0=0,0 end

  --get effective gyro angle considering body angle offset
  if not active then yawAngle = (uLeft[3]+uRight[3])/2-uTorsoActual[3] --double support
  elseif supportLeg == 0 then yawAngle = uLeft[3]-uTorsoActual[3] -- Left support
  elseif supportLeg==1 then yawAngle = uRight[3]-uTorsoActual[3]
  end
  gyro_roll = gyro_roll0*math.cos(yawAngle) -gyro_pitch0* math.sin(yawAngle)
  gyro_pitch = gyro_pitch0*math.cos(yawAngle) -gyro_roll0* math.sin(yawAngle)

  ankleShiftX=util.procFunc(gyro_pitch*ankleImuParamX[2],ankleImuParamX[3],ankleImuParamX[4])
  ankleShiftY=util.procFunc(gyro_roll*ankleImuParamY[2],ankleImuParamY[3],ankleImuParamY[4])
  kneeShiftX=util.procFunc(gyro_pitch*kneeImuParamX[2],kneeImuParamX[3],kneeImuParamX[4])
  hipShiftY=util.procFunc(gyro_roll*hipImuParamY[2],hipImuParamY[3],hipImuParamY[4])

  ankleShift[1]=ankleShift[1]+ankleImuParamX[1]*(ankleShiftX-ankleShift[1]);
  ankleShift[2]=ankleShift[2]+ankleImuParamY[1]*(ankleShiftY-ankleShift[2]);
  kneeShift=kneeShift+kneeImuParamX[1]*(kneeShiftX-kneeShift);
  hipShift[2]=hipShift[2]+hipImuParamY[1]*(hipShiftY-hipShift[2]);

  if not active then --Double support, standing still
    qLegs[4] = qLegs[4] + kneeShift; --Knee pitch stabilization
    qLegs[5] = qLegs[5] + ankleShift[1]; --Ankle pitch stabilization
    qLegs[10] = qLegs[10] + kneeShift; --Knee pitch stabilization
    qLegs[11] = qLegs[11] + ankleShift[1]; --Ankle pitch stabilization

  elseif supportLeg == 0 then -- Left support
    qLegs[2] = qLegs[2] + hipShift[2]; --Hip roll stabilization
    qLegs[4] = qLegs[4] + kneeShift; --Knee pitch stabilization
    qLegs[5] = qLegs[5] + ankleShift[1]; --Ankle pitch stabilization
    qLegs[6] = qLegs[6] + ankleShift[2]; --Ankle roll stabilization

    qLegs[11] = qLegs[11] + toeTipCompensation*phComp;--Lifting toetip
    qLegs[2] = qLegs[2] + cp.hipRollCompensation*phComp; --Hip roll compensation
  else
    qLegs[8] = qLegs[8] + hipShift[2]; --Hip roll stabilization
    qLegs[10] = qLegs[10] + kneeShift; --Knee pitch stabilization
    qLegs[11] = qLegs[11] + ankleShift[1]; --Ankle pitch stabilization
    qLegs[12] = qLegs[12] + ankleShift[2]; --Ankle roll stabilization

    qLegs[5] = qLegs[5] + toeTipCompensation*phComp;--Lifting toetip
    qLegs[8] = qLegs[8] - cp.hipRollCompensation*phComp;--Hip roll compensation
  end

  qLegs[3] = qLegs[3] + Config.walk.LHipOffset
  qLegs[9] = qLegs[9] + Config.walk.RHipOffset
  qLegs[5] = qLegs[5] + Config.walk.LAnkleOffset
  qLegs[11] = qLegs[11] + Config.walk.RAnkleOffset
  if not dontmove then
    Body.set_lleg_command(qLegs);
  end
  if deltaT>dlt0 then
    if useremote1 and false then
      send_message="robo_msg";
      for curr_id=1,12 do
        cur_pos= qLegs[curr_id];
        cur_pos=rounddeci(cur_pos,5);
        send_message=send_message.."|"..cur_pos;
      end
      send_message=send_message.."|"..supportLeg;
      send_message=send_message.."|"..phSingle;
      send_message=send_message.."|"..pTorso[5];

      for i=1,3 do
        send_message=send_message.."|"..pTorso[i];
      end
      for i=1,3 do
        send_message=send_message.."|"..pLLeg[i];
      end
      for i=1,3 do
        send_message=send_message.."|"..pRLeg[i];
      end
      publisher:sendx(send_message);
    end
  end
end

function exit() end

function step_left_destination(vel, uLeft, uRight)
  local u0 = util.se2_interpolate(.5, uLeft, uRight);
  -- Determine nominal midpoint position 1.5 steps in future
  local u1 = util.pose_global(vel, u0);
  local fact = 2-1.5*math.exp(-8*(0.06-math.abs(vel[1])));
  if unlock_kick >0 then
    vel[1]=0.0;
    vel[3]=0;
  end
  local u2 = util.pose_global(fact*vel, u1);  --- TODO XIANG TODO
  local uLeftPredict = util.pose_global(uLRFootOffset, u2);
  local uLeftRight = util.pose_relative(uLeftPredict, uRight);

  --Check toe and heel overlap
  local toeOverlap= -footSizeX[1]*uLeftRight[3];
  local heelOverlap= -footSizeX[2]*uLeftRight[3];
  local limitY = math.max(stanceLimitY[1],
    stanceLimitY2+math.max(toeOverlap,heelOverlap));

  uLeftRight[1] = math.min(math.max(uLeftRight[1], stanceLimitX[1]), stanceLimitX[2]);
  uLeftRight[2] = math.min(math.max(uLeftRight[2], limitY),stanceLimitY[2]);
  uLeftRight[3] = math.min(math.max(uLeftRight[3], stanceLimitA[1]), stanceLimitA[2]);
  return util.pose_global(uLeftRight, uRight);
end

function step_right_destination(vel, uLeft, uRight)
  local u0 = util.se2_interpolate(.5, uLeft, uRight);
  -- Determine nominal midpoint position 1.5 steps in future
  local u1 = util.pose_global(vel, u0);
  local fact = 2-1.5*math.exp(-8*(0.06-math.abs(vel[1])));
  if unlock_kick >0 then
    vel[1]=0.0;
    vel[3]=0;
  end
  local u2 = util.pose_global(fact*vel, u1); --- TODO XIANG TODO
  local uRightPredict = util.pose_global(-1*uLRFootOffset, u2);
  local uRightLeft = util.pose_relative(uRightPredict, uLeft);

  --Check toe and heel overlap
  local toeOverlap= footSizeX[1]*uRightLeft[3];
  local heelOverlap= footSizeX[2]*uRightLeft[3];
  local limitY = math.max(stanceLimitY[1],
    stanceLimitY2+math.max(toeOverlap,heelOverlap));

  uRightLeft[1] = math.min(math.max(uRightLeft[1], stanceLimitX[1]), stanceLimitX[2]);
  uRightLeft[2] = math.min(math.max(uRightLeft[2], -stanceLimitY[2]), -limitY);
  uRightLeft[3] = math.min(math.max(uRightLeft[3], -stanceLimitA[2]), -stanceLimitA[1]);
  return util.pose_global(uRightLeft, uLeft);
end

function step_torso(uLeft, uRight,shiftFactor)
  local u0 = util.se2_interpolate(.5, uLeft, uRight);
  local uLeftSupport = util.pose_global({cp.supportX, cp.supportY, 0}, uLeft);
  local uRightSupport = util.pose_global({cp.supportX, -cp.supportY, 0}, uRight);
  return util.se2_interpolate(shiftFactor, uLeftSupport, uRightSupport);
end

function set_velocity(vx, vy, va)
  --Filter the commanded speed
  vx= math.min(math.max(vx,velLimitX[1]),velLimitX[2]);
  vy= math.min(math.max(vy,velLimitY[1]),velLimitY[2]);
  va= math.min(math.max(va,velLimitA[1]),velLimitA[2]);

  --Slow down when turning
  vFactor = 1-math.abs(va)/vaFactor;

  local stepMag=math.sqrt(vx^2+vy^2);
  local magFactor=math.min(velLimitX[2]*vFactor,stepMag)/(stepMag+0.000001);

  velCommand[1],velCommand[2],velCommand[3]=vx*magFactor,vy*magFactor,va

  velCommand[1] = math.min(math.max(velCommand[1],velLimitX[1]),velLimitX[2]);
  velCommand[2] = math.min(math.max(velCommand[2],velLimitY[1]),velLimitY[2]);
  velCommand[3] = math.min(math.max(velCommand[3],velLimitA[1]),velLimitA[2]);
end

function update_velocity()
  local sf = 1
  if max_unstable_factor> 0.7 then -- robot's unstable, slow down
    print("unstable, slowing down")
    sf = 0.85
  end

  if velCurrent[1]>velXHigh then --Slower accelleration at high speed
    velDiff[1]= math.min(math.max(velCommand[1]*sf-velCurrent[1],-velDelta[1]),velDeltaXHigh)
  else
    velDiff[1]= math.min(math.max(velCommand[1]*sf-velCurrent[1],-velDelta[1]),velDelta[1])
  end
  velDiff[2]= math.min(math.max(velCommand[2]*sf-velCurrent[2],-velDelta[2]),velDelta[2])
  velDiff[3]= math.min(math.max(velCommand[3]*sf-velCurrent[3],-velDelta[3]),velDelta[3])
  velCurrent = velCurrent+velDiff

  if initial_step>0 then
    velCurrent=vector.new({0,0,0})
    initial_step=initial_step-1
  end
end

function get_velocity() return velCurrent end

function start()
  stopRequest = 0;
  if (not active) then
    active = true
    started = false
    iStep0 = -1
    tLastStep = Body.get_time()
    initial_step=2
  end
end

function doWalkKickLeft()
  if walkKickRequest==0 then
    walkKickRequest = 1;
    walkKick = walkKickDef["FrontLeft"];
  end
  if not kickcommandpause then
    leftkick=true;
    print('leftkick true \n')
  end
end

function doWalkKickRight()
  if walkKickRequest==0 then
    walkKickRequest = 1;
    walkKick = walkKickDef["FrontRight"];
  end
  if not kickcommandpause then
    leftkick=false;
  end
end

function doWalkKickLeft2()
  if walkKickRequest==0 then
    walkKickRequest = 1;
    walkKick = walkKickDef["FrontLeft2"];
  end
end

function doWalkKickRight2()
  if walkKickRequest==0 then walkKickRequest = 1
    walkKick = walkKickDef["FrontRight2"] end
end

function doSideKickLeft()
  if walkKickRequest==0 then
    walkKickRequest = 1;
    walkKick = walkKickDef["SideLeft"];
  end
end

function doSideKickRight()
  if walkKickRequest==0 then
    walkKickRequest = 1;
    walkKick = walkKickDef["SideRight"];
  end
end

function zero_velocity() end
function doPunch(punchtype) end
function switch_stance(stance) end
function stop() stopRequest = math.max(1,stopRequest) end
function stopAlign() stop() end

function stance_reset() --standup/sitdown/falldown handling
  print("Stance Resetted")
  uLeft = util.pose_global(vector.new({-cp.supportX, cp.footY, 0}),uTorso)
  uRight = util.pose_global(vector.new({-cp.supportX, -cp.footY, 0}),uTorso)
  uLeft1, uLeft2,uRight1, uRight2,uTorso1, uTorso2 = uLeft, uLeft, uRight, uRight, uTorso, uTorso
  uSupport = uTorso
  tLastStep=Body.get_time()
  walkKickRequest = 0
  iStep0,iStep = -1,0
  walkKickRequest=0
  uLRFootOffset = vector.new({0,footY,0});
end

function get_odometry(u0)
  if (not u0) then
    u0 = vector.new({0, 0, 0});
  end
  local uFoot = util.se2_interpolate(.5, uLeft+uLeftoff, uRight+uRightoff);
  return util.pose_relative(uFoot, u0), uFoot;
end

function get_body_offset()
  local uFoot = util.se2_interpolate(.5, uLeft+uLeftoff, uRight+uRightoff);
  return util.pose_relative(uTorso+uTorsooff, uFoot);
end

function calculate_zmp_param(uSupport,uTorso1,uTorso2,p)
  local zmpparam={}
  if p.zmp_type==1 then
    zmpparam.m1X = (uSupport[1]-uTorso1[1])/(p.tStep*p.phSingleRatio/2)
    zmpparam.m2X = (uTorso2[1]-uSupport[1])/(p.tStep*p.phSingleRatio/2)
    zmpparam.m1Y = (uSupport[2]-uTorso1[2])/(p.tStep*p.phSingleRatio/2)
    zmpparam.m2Y = (uTorso2[2]-uSupport[2])/(p.tStep*p.phSingleRatio/2)
  end
  zmpparam.aXP, zmpparam.aXN = zmp_solve(uSupport[1], uTorso1[1], uTorso2[1],uTorso1[1], uTorso2[1],p)
  zmpparam.aYP, zmpparam.aYN = zmp_solve(uSupport[2], uTorso1[2], uTorso2[2],uTorso1[2], uTorso2[2],p)
  p.zmpparam = zmpparam
  --Compute COM speed at the end of step
  --[[
    dx0=(aXP-aXN)/tZmp + m1X* (1-math.cosh(ph1Zmp*tStep/tZmp));
    dy0=(aYP-aYN)/tZmp + m1Y* (1-math.cosh(ph1Zmp*tStep/tZmp));
    print("max DY:",dy0);
    --]]
end

function zmp_solve(zs, z1, z2, x1, x2,p)
  --[[
    Solves ZMP equation:
    x(t) = z(t) + aP*exp(t/tZmp) + aN*exp(-t/tZmp) - tZmp*mi*sinh((t-Ti)/tZmp)
    where the ZMP point is piecewise linear:
    z(0) = z1, z(T1 < t < T2) = zs, z(tStep) = z2
    --]]
  local expTStep = math.exp(p.tStep/p.tZmp);
  if p.zmp_type==1 then --Trapzoidal zmp
    local T1,T2 = p.tStep*p.phSingleRatio/2, p.tStep*(1-p.phSingleRatio/2)
    local m1,m2 = (zs-z1)/T1, -(zs-z2)/(p.tStep-T2)
    local c1 = x1-z1+p.tZmp*m1*math.sinh(-T1/p.tZmp);
    local c2 = x2-z2+p.tZmp*m2*math.sinh((p.tStep-T2)/p.tZmp);
    local aP = (c2 - c1/expTStep)/(expTStep-1/expTStep);
    local aN = (c1*expTStep - c2)/(expTStep-1/expTStep);
    return aP, aN;
  else --Square ZMP
    local c1 = x1-z1
    local c2 = x2-z2
    local aP = (c2 - c1/expTStep)/(expTStep-1/expTStep)
    local aN = (c1*expTStep - c2)/(expTStep-1/expTStep)
  end
end

--Finds the necessary COM for stability and returns it
function zmp_com(ph,p)
  local com = vector.new({0, 0, 0});
  local tStep,ph1Zmp,ph2Zmp,tZmp =p.tStep, p.phSingleRatio/2,1-p.phSingleRatio/2, p.tZmp
  local m1X,m1Y,m2X,m2Y = p.zmpparam.m1X,p.zmpparam.m1Y,p.zmpparam.m2X,p.zmpparam.m2Y
  local aXP,aXN,aYP,aYN = p.zmpparam.aXP,p.zmpparam.aXN,p.zmpparam.aYP,p.zmpparam.aYN
  expT = math.exp(tStep*ph/tZmp);
  com[1] = uSupport[1] + aXP*expT + aXN/expT;
  com[2] = uSupport[2] + aYP*expT + aYN/expT;
  if p.zmp_type==1 then
    if (ph < ph1Zmp) then
      com[1] = com[1] + m1X*tStep*(ph-ph1Zmp) - tZmp*m1X*math.sinh(tStep*(ph-ph1Zmp)/tZmp);
      com[2] = com[2] + m1Y*tStep*(ph-ph1Zmp) - tZmp*m1Y*math.sinh(tStep*(ph-ph1Zmp)/tZmp);
    elseif (ph > ph2Zmp) then
      com[1] = com[1] + m2X*tStep*(ph-ph2Zmp) - tZmp*m2X*math.sinh(tStep*(ph-ph2Zmp)/tZmp);
      com[2] = com[2] + m2Y*tStep*(ph-ph2Zmp) - tZmp*m2Y*math.sinh(tStep*(ph-ph2Zmp)/tZmp);
    end
  end
  com[3] = ph* (uLeft2[3]+uRight2[3])/2 + (1-ph)* (uLeft1[3]+uRight1[3])/2;
  return com;
end

function foot_phase(ph)
  -- Computes relative x,z motion of foot during single support phase
  -- phSingle = 0: x=0, z=0, phSingle = 1: x=1,z=0
  local ph1Single,ph2Single = cp.phSingleRatio/2,1-cp.phSingleRatio/2
  phSingle = math.min(math.max(ph-ph1Single, 0)/(ph2Single-ph1Single),1);
  local phSingleSkew = phSingle^0.8 - 0.17*phSingle*(1-phSingle);
  local xf = .5*(1-math.cos(math.pi*phSingleSkew));
  local zf = .5*(1-math.cos(2*math.pi*phSingleSkew));
  return xf, zf
end

function calculate_swap()
  if (not Config.walk.variable_step) or Config.walk.variable_step==0 then
    return Config.walk.tStep
  end

  require('invhyp')
  --x = p + x0 cosh((t-t0)/t_zmp)
  --local tStep = cp.tStep
  local tStep = Config.walk.tStep
  local tZmp = cp.tZmp

  local stepY
  local t_start
  local p,x0
  if supportLeg==0 then --ls
    p = -(cp.footY + cp.supportY)
    x0 = -p/math.cosh(tStep/tZmp/2)
    local uSupport1 = util.pose_global({cp.supportX, cp.supportY, 0}, uLeft1);
    local uSupport2 = util.pose_global({cp.supportX, -cp.supportY, 0}, uRight2);
    local uSupportMove = util.pose_relative(uSupport2,uSupport1)
    stepY = uSupportMove[2]+2*(cp.footY+cp.supportY)
    -- print("ls",stepY)
  else --rs
    p = (cp.footY + cp.supportY)
    x0 = -p/math.cosh(tStep/tZmp/2)
    local uSupport1 = util.pose_global({cp.supportX, -cp.supportY, 0}, uRight1);
    local uSupport2 = util.pose_global({cp.supportX, cp.supportY, 0}, uLeft2);
    uSupportMove = util.pose_relative(uSupport2,uSupport1)
    stepY = uSupportMove[2]-2*(cp.footY+cp.supportY)
    -- print("rs",stepY)
  end
  if (stepY/2-p)/x0<1 then return Config.walk.tStep end
  local t_start = -invhyp.acosh( (stepY/2 - p)/x0 )*tZmp + tStep/2
  local tStep_next = math.max(Config.walk.tStep, tStep-t_start)
  -- print("tStep_next:",tStep_next)
  return tStep_next
end

entry()
