---New Locomotion for RoboCup2018!
---Author of correspondence for locomotion 2018:
-- Xiang Deng, dxiang@seas.upenn.edu
module(..., package.seeall);

-- require "zhelpers"
-- local zmq = require "lzmq"
--
-- -- Prepare our context and publisher
-- local context = zmq.context()
-- local publisher, err = context:socket{zmq.PUB, bind = "tcp://*:5564"}
-- zassert(publisher, err)
-- local subscriber, err = context:socket{zmq.SUB,
--   subscribe = "control_msg";
--   connect = "tcp://192.168.123.99:5563";
-- }
-- zassert(subscriber, err)
-- print('lmzq setup',zmq);
function comm_States( qall ,qLeg_command)

  -- local control_contents = subscriber:recvx();
  -- control_pkg=mysplit(control_contents,'|');
  -- for i=1,#control_pkg do
  -- control_pkg[i]=tonumber( control_pkg [i]);
  -- end
  -- new_control=true;
  -- print(unpack(control_pkg))
  -- print('imuAngle',unpack(imuAngle))
  send_message="robo_msg";
  for curr_id=1,#qall do
    cur_pos= qall[curr_id];
    cur_pos=rounddeci(cur_pos,5);
    send_message=send_message.."|"..cur_pos;
  end
  for curr_id=1,#qLeg_command do
    cur_pos= qLeg_command[curr_id];
    cur_pos=rounddeci(cur_pos,5);
    send_message=send_message.."|"..cur_pos;
  end
  publisher:sendx(send_message);
end

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

test2018=true;
usewebots=true;
logdata=false;
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
myWalk=require('liblibNAOWalk')
myWalk.init(0);
-----------------------------
local matrix = require('matrix');
--------------------------------

for i=1,100 do
  print('Config.walk.footX',Config.walk.footX)
end

--- XIANG's motion lib --------------------
kick_strike=false;
kick_stage=0;
kicksign=1;

step_h_goal=0.01;
step_h_cur=0.01;

getup_active=false;
getup_activeB=false;
getup_started=false;
getup_startedB=false;
t0_stance= Body.get_time();
stance_started=false;
s_getup=0;
qcontrol=vector.zeros(22);

diff_m=vector.zeros(3);
diff_md=vector.zeros(3);

nJoints=22;

supportXauto=0.022;
supportLeg=0;

ft_left_f=vector.zeros(3);
ft_left_b=vector.zeros(3);
ft_right_f=vector.zeros(3);
ft_right_b=vector.zeros(3);
ft_m=vector.zeros(3);
diff_m=vector.zeros(3);
diff_md=vector.zeros(3);

hip_range_table = {{-1.145303, 0.740810}, -- hip yaw pitch
  {-0.379472, 0.790477}, -- left hip roll
  {-1.535889, 0.484090}, -- left hip pitch
  {-0.092346, 2.112528}, -- left knee pitch
  {-1.189516, 0.922747}, -- left ankle pitch
  {-0.397880, 0.769001}, -- left ankle roll
  {-1.145303, 0.740810}, -- hip yaw pitch
  {-0.790477, 0.379472}, -- right hip roll
  {-1.535889, 0.484090}, -- right hip pitch
  {-0.103083, 2.120198}, -- right knee pitch
  {-1.186448, 0.932056}, -- right ankle pitch
  {-0.768992, 0.397935}} -- right ankle roll

function saturate_leg_joints(qlegs)
  local i = 0
  for i = 1, 12 do
    qlegs[i] = math.min(qlegs[i], hip_range_table[i][2]);
    qlegs[i] = math.max(qlegs[i], hip_range_table[i][1]);
  end
  return qlegs;
end
--------------------------------

-- Walk Parameters
-- Stance and velocity limit values
stanceLimitX=Config.walk.stanceLimitX or {-0.10 , 0.10};
stanceLimitY=Config.walk.stanceLimitY or {0.09 , 0.20};
stanceLimitY={2*Config.walk.footY - 2*Config.walk.supportY,0.20} --needed to prevent from tStep getting too small
stanceLimitA=Config.walk.stanceLimitA or {-0*math.pi/180, 40*math.pi/180};
velLimitX = {-.05, .07};
velLimitY = {-.08, .08};
velLimitA = {-.5, .5};
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

function update_stance()
  local t = Body.get_time();

  -- pTorsoTarget = vector.new({-footXSit, 0, bodyHeightSit, 0,bodyTiltSit,0});

  local footX = 0.01
  print('footX',footX)

  local uTorsoActual = util.pose_global(vector.new({-footX,0,0}), uTorso);
  local pTorsoTarget=vector.new({uTorsoActual[1], uTorsoActual[2], cp.bodyHeight, 0,cp.bodyTilt,uTorsoActual[3]});
  local pLLeg = vector.new({uLeft[1], uLeft[2], 0, 0,0,uLeft[3]});
  local pRLeg = vector.new({uRight[1], uRight[2], 0, 0,0,uRight[3]});

  if not stance_started then
    if t-t0_stance>0.02 then
      stance_started=true;
      local qLLeg = Body.get_lleg_position();
      local qRLeg = Body.get_rleg_position();

      local dpLLeg = Kinematics.torso_lleg(qLLeg);
      local dpRLeg = Kinematics.torso_rleg(qRLeg);
      pTorsoL=pLLeg+dpLLeg;
      pTorsoR=pRLeg+dpRLeg;
      pTorso=(pTorsoL+pTorsoR)*0.5;

      Body.set_lleg_command(qLLeg);
      Body.set_rleg_command(qRLeg);
      -- TODO
      Body.set_lleg_hardness(0.5);
      Body.set_rleg_hardness(0.5);
      t0_stance = Body.get_time();
      count=1;
    else
      return;
    end
  end

  local dt = t - t0_stance;
  t0_stance = t;
  local tol = true;
  local tolLimit = 1e-6;
  dpLimit = Config.stance.dpLimitStance
  dpDeltaMax = dt*dpLimit;

  dpTorso = pTorsoTarget - pTorso;
  for i = 1,6 do
    if (math.abs(dpTorso[i]) > tolLimit) then
      tol = false;
      if (dpTorso[i] > dpDeltaMax[i]) then
        dpTorso[i] = dpDeltaMax[i];
      elseif (dpTorso[i] < -dpDeltaMax[i]) then
        dpTorso[i] = -dpDeltaMax[i];
      end
    end
  end

  pTorso=pTorso+dpTorso;

  pTorsoActual = {
    pTorso[1],
    pTorso[2],
    pTorso[3],
    pTorso[4],
    pTorso[5],
    pTorso[6]}
  -- print('pLLeg',pLLeg)
  q = Kinematics.inverse_legs(pLLeg, pRLeg, pTorsoActual, 0);

  --print(q[9])
  Body.set_lleg_command(q);

  if tol then
    stance_started=false;
    stance_reset();
    return 1;
  end

  return 0;

end

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
  p.supportY=0.05
  -- p.footY =0.055
  -- p.supportY =0.055;

  p.tZmp = Config.walk.tZmp

  p.tZmp=0.2
  p.tZmpX=0.16
  p.tZmpY=0.23 ;

  -- print('p.tZmp',p.tZmp,'p.tStep ',p.tStep )
  --
  -- p.tStep=p.tStep*4;
  -- p .tStep0=p .tStep0*4;
  -- p.tZmp=p.tZmp*4;

  -- p.stepHeight0 = Config.walk.stepHeight
  -- p.stepHeight = Config.walk.stepHeight

  steph=0.02;
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
uTorsoDX=uTorso;--DX
uLeft = vector.new({0, Config.walk.footY, 0});
uRight = vector.new({0, -Config.walk.footY, 0});
velCurrent, velCommand,velDiff = vector.new({0,0,0}),vector.new({0,0,0}),vector.new({0,0,0})

--Gyro stabilization variables
ankleShift,kneeShift,hipShift,toeTipCompensation = vector.new({0,0}),0,vector.new({0,0}),0

active = true;
started = false;
iStep0,iStep = 0,0
tLastStep = Body.get_time()

stopRequest = 0; --2 DX
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

emergency=false;

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
  file:write( jointstr, "\n")

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
if logdata then
  writedatatofile_headers();
end
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
  myWalk.LIPMLearnerInit(cp.tStep,step_h_goal,cp.bodyHeight)


  stopRequest=0; --DX
  start()--DX
end

-----------------------------------------------------
usearm=true;
walk_dir_compens=0.03;
vel_backwds=-0.005;
vel_zero_fwoff=0.01;
prev_pitch=0;
vel_pitch={};
vel_pitch.y_hat=0;
vel_pitch.kp=10;
vel_pitch.ki=0.01;
vel_pitch.error_acc=0;
prev_roll=0;
vel_roll={};
vel_roll.y_hat=0;
vel_roll.kp=10;
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
  vel_qi.kp=10;
  vel_qi.ki=0.01;
  vel_qi.error_acc=0;
  vels_ql[i]=vel_qi;
end
vels_qr={};
for i=1,6 do
  vel_qi={};
  vel_qi.y_hat=0;
  vel_qi.kp=10;
  vel_qi.ki=0.01;
  vel_qi.error_acc=0;
  vels_qr[i]=vel_qi;
end

vels_diffm={}
for i=1,3 do
  vel_qi={};
  vel_qi.y_hat=0;
  vel_qi.kp=10;
  vel_qi.ki=0.01;
  vel_qi.error_acc=0;
  vels_diffm[i]=vel_qi;
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
fsRL_t=0;
fsRR_t=0;
function computeZMPfromSensor()
  lfsr=Body.get_sensor_fsrLeft();
  rfsr=Body.get_sensor_fsrRight();
  fsRL_t=0;
  fsRR_t=0;
  for i=1,4 do
    fsRL_t=fsRL_t+lfsr[i];
    fsRR_t=fsRR_t+rfsr[i];
  end
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
function plan_nextstep()
  update_velocity();
  iStep0 = iStep;
  local tStep_next = calculate_swap()

  supportLeg = iStep % 2; -- 0 for left support, 1 for right support
  uLeft1,uRight1,uTorso1 = uLeft2,uRight2,uTorso2

  --Switch walk params
  cp = np
  np = load_default_param_values()

  if (step_h_cur~=step_h_goal) then
    step_h_cur=step_h_cur+(step_h_goal-step_h_cur)*0.3;
  end

  np.stepHeight=step_h_cur+math.max(math.abs(velCurrent[1])*1.7,math.abs(velCurrent[2])*2)*0.1+math.abs(velCurrent[3])*0.02*0;
  np.stepHeight0=step_h_cur+math.max(math.abs(velCurrent[1])*1.7,math.abs(velCurrent[2])*2)*0.1+math.abs(velCurrent[3])*0.02*0;

  -- print('stepHeight0',np.stepHeight0)--Dx mark here
  -- np.stepHeight=0.016;---- *<<<<<<PARAM>>>>>/
  if walkKickRequest==0 then
    np.tStep0 = tStep_next
    np.tStep = tStep_next
  end

  uLRFootOffset = vector.new({0,cp.footY,0})
  supportMod = {0,0}; --Support Point modulation for walkkick
  shiftFactor = 0.5; --How much should we shift final Torso pose?
  -- check_walkkick();
  -- xiang_walkkick_0step();
  if walkKickRequest>0 then --DX
    velCurrent={0,0,0}
    -- print('uLeft2b',uLeft2b,'uRight2b',uRight2b,'uTorso2b',uTorso2b)
  end
  if supportLeg == 0 then --LS
    local pack=myWalk.Xiang_walkkick(uLeft1,kicksign);
    uLeft2b=vector.new(pack[1]);
    uRight2b=vector.new(pack[2]);
    uTorso2b=vector.new(pack[3]);
  else
    local pack=myWalk.Xiang_walkkick(uRight1,kicksign);
    uLeft2b=vector.new(pack[1]);
    uRight2b=vector.new(pack[2]);
    uTorso2b=vector.new(pack[3]);
  end

  ----------------------------------
  if walkKickRequest==0 then
    if (stopRequest>0) then --Final step --==1 DX
      -- stopRequest=2 --DX
      velCurrent,velCommand=vector.new({0,0,0}),vector.new({0,0,0}) ;
      myWalk.setvelCurrent(velCurrent)
      if supportLeg == 0 then uRight2 = util.pose_global(-2*uLRFootOffset, uLeft1) --LS
        uLeft2=uLeft1
      else uLeft2 = util.pose_global(2*uLRFootOffset, uRight1) --RS
        uRight2=uRight1
      end
    else --Normal walk, advance steps
      cp.tStep=cp.tStep0
      if supportLeg == 0 then --LS
        uRight2 = step_right_destination(velCurrent, uLeft1, uRight1) --LS
        uLeft2=uLeft1;--DX

      else
        uLeft2 = step_left_destination(velCurrent, uLeft1, uRight1) --RS
        uRight2=uRight1;--DX
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
  if walkKickRequest>0 then --DX
    -- print('uLeft2b',uLeft2b,'uRight2b',uRight2b,'uTorso2b',uTorso2b)
    uLeft2=uLeft2b;
    uRight2=uRight2b;
    uTorso2=uTorso2b;
  end

  -- print('uLeft2',uLeft2)
  -- print('uRight2',uRight2)
  --Adjustable initial step body swing
  if initial_step>0 then
    if supportLeg == 0 then supportMod[2]=supportModYInitial --LS
    else supportMod[2]=-supportModYInitial end--RS
  end

  --Apply velocity-based support point modulation for uSupport
  if supportLeg == 0 then --LS
    -- local uLeftTorso = util.pose_relative(uLeft1,uTorso1);
    -- local uTorsoModded = util.pose_global(vector.new({supportMod[1],supportMod[2],0}),uTorso)
    -- local uLeftModded = util.pose_global (uLeftTorso,uTorsoModded);
    uSupport = util.pose_global({cp.supportX, cp.supportY, 0},uLeft1)--DX TODO disable this for now

    Body.set_lleg_hardness(cp.hardnessSupport);
    Body.set_rleg_hardness(cp.hardnessSwing);

  else --RS
    -- local uRightTorso = util.pose_relative(uRight1,uTorso1);
    -- local uTorsoModded = util.pose_global(vector.new({supportMod[1],supportMod[2],0}),uTorso)
    -- local uRightModded = util.pose_global (uRightTorso,uTorsoModded);
    uSupport = util.pose_global({cp.supportX, -cp.supportY, 0}, uRight1)--DX TODO disable this for now

    Body.set_rleg_hardness(cp.hardnessSupport);
    Body.set_lleg_hardness(cp.hardnessSwing);

  end
  -- print('cp.tStep',cp.tStep,'cp.tZmp',cp.tZmp,'cp.phSingleRatio',cp.phSingleRatio)
  -- print('ph',ph,'cp.supportY',cp.supportY,'cp.footY',cp.footY)
  --Dx mark here
  -- print('uSupport[1]',uSupport[1],'uTorso1[1]',uTorso1[1],'uTorso2[1]',uTorso2[1],'uTorso[1]',uTorso[1] )
  -- print('uSupport[2]',uSupport[2],'uTorso1[2]',uTorso1[2],'uTorso2[2]',uTorso2[2],'uTorso[2]',uTorso[2] )
  -- print('uSupport[2]',uSupport[2],'uRight2[2]',uRight2[2],'uLeft2[2]',uLeft2[2],'uTorso1[2]',uTorso1[2],'uTorso2[2]',uTorso2[2],'uTorso[2]',uTorso[2] )
  -- print('calculate_zmp_param',iStep, supportLeg, uSupport,uTorso2,uTorso1)
  --DX
  myWalk.calculate_zmp_param(util.pose_relative(uSupport,uTorso1), util.pose_relative(uSupport,uTorso2))

  max_unstable_factor=0
  isnewstep=true;
end

taf=-1;
function set_taf(taf_in) --DX
  taf=taf_in;
end
function start()

  if (not active) then --TODO cleanup,,,,,
    active = true
    -- started = false
    -- iStep0 = -1
    -- iStep0=0;
    -- iStep=0;
    -- tLastStep = Body.get_time()
    initial_step=2
    cp=load_default_param_values();

  end
  -- print('behavior wants resume--------')
  -- if (stopRequest>0) then
  --   print('but not stopped yet=====')
  -- end
  -- if stopRequest>0 or myWalk.isStopped(0)>0  then --DX
  --   myWalk.resume(0)
  --   print('resume--------')
  --   tLastStep = Body.get_time()
  --   cp=load_default_param_values();
  -- end
  -- stopRequest = 0;


  if myWalk.isStopped(0)>0 then
    myWalk.resume(0);
    stopRequest=0;
      active = true
      -- started = false
      -- iStep0 = -1
      -- iStep0=0;
      -- iStep=0;
      -- tLastStep = Body.get_time()
      initial_step=2
      cp=load_default_param_values();
      print('A---------')
  elseif stopRequest>0 then
    print('B---------')
    stopRequest=0.5;
  else
    print('C---------')
    -- stopRequest=0;
    -- active=true;
    -- tLastStep = Body.get_time()
    -- iStep0=0
    --nothing, is already started
  end
end
function stop()
  -- stopRequest = math.max(1,stopRequest) --DX
  if stopRequest<1 then
    stopRequest=1;
    myWalk.stop(0);
    print('stop requested------')
  end
end

function normalloop()

    if (not started) then
      started=true;
      tLastStep = Body.get_time();
      iStep0=0;
      iStep=0;
      print('start walk_-----------------')
      plan_nextstep()
    end


  computeZMPfromSensor();
  if cnter % 50 ==0 then
    -- print ('ZMPL ', ZMPL,'ZMPFl ', ZMPFl, 'ZMPFr ', ZMPFr)
  end
  myWalk.setZMPL(ZMPL);
  myWalk.setFootPressures(fsRL_t,fsRR_t);

  footX = mcm.get_footX()
  -- print('myWalk.isStopped(0)',myWalk.isStopped(0))
  if (myWalk.isStopped(0)>0 ) then --DX

    if ( stopRequest<=0.5) then
      -- print('herherhe',stopRequest)
      start()
      -- return
    else
      active=false;--feedback to sit request DX
      -- active=false or ( is_stopped)
    end
  end
  --for obstacle detection
  if mcm.get_us_frontobs() == 1 and obscheck == true then
    vy, va = velCurrent[2],velCurrent[3]
    set_velocity(-0.02, 0, 0)
    print("obstacle!!!!!")
  end

  --Don't run update if the robot is sitting or standing
  if vcm.get_camera_bodyHeight()<cp.bodyHeight-0.01 then return end
    -- print('myWalk.isStopped',myWalk.isStopped(0))
  if (not active) then mcm.set_walk_isMoving(0);update_still() return end

  mcm.set_walk_isMoving(1)




  cnter=cnter+1;
  t = Body.get_time()
  if cnter % 20==0 and logdata then
    writedatatofile_joints();
  end
  -- imuAngle = Body.get_sensor_imuAngle();
  -- print("imuAngle:",imuAngle[1]*180/math.pi,imuAngle[2]*180/math.pi)



  local unstable_factor = math.max (
    math.abs(imuAngle[1]) / stop_threshold[1],
    math.abs(imuAngle[2]) / stop_threshold[2]
  )
  max_unstable_factor = math.max(unstable_factor, max_unstable_factor)

  --start emergency stop
  if dontmove then
    tStopDuration= 2
    print(tStopDuration)
    stopRequest = 2
    tStopStart = t
    velCurrent= {0,0,0}
    is_stopped = true
  end
  --end emergency stop
  -- print('is_stopped tStopStart tStopDuration t',is_stopped, tStopStart, tStopDuration, t)
  if is_stopped and t>tStopStart+tStopDuration then
    print('resume from emergency----------') --Dx
    is_stopped = false
    start()
    return
  end







  local timeSinceStep=(t-tLastStep)
  --debug...
  -- if supportLeg==0 then
  -- print('p0lra',util.pose_relative(uLeft1,uRight1))--DX
  -- print('p0lrb',util.pose_relative(uRight2,uLeft1))--DX
  -- else
  -- print('p0lra',util.pose_relative(uRight1,uLeft1))--DX
  -- print('p0lrb',util.pose_relative(uLeft2,uRight1))--DX
  -- end
  -- print('walkKickRequest ',walkKickRequest)
  local pack=myWalk.Xiang_walknormalloopII(step_h_cur, uLeft1, uLeft2, uRight1, uRight2, timeSinceStep, walkKickRequest);--TODO kick
  notswap=pack[1];
  phaseb=pack[2];
  uLeftb=vector.new(pack[3]);
  uRightb=vector.new(pack[4]);
  uTorsob=vector.new(pack[5]);
  kick_stageb=pack[6];
  kick_doneb=pack[7];
  emergencyb=pack[8];
  iStep=pack[9]

   --DX myWalk will compute iStep
  --Stop when stopping sequence is done
  -- if (iStep > iStep0) and(stopRequest==2) then
  --   stopRequest = 0
  --   -- active = false --DX
  --   step_h_cur=0.00;
  --   return "stop"
  -- end

  ----------------
  -- New step
  if (iStep > iStep0) then
    -- print('notswap ',notswap)
    -- print('iStep ',iStep,'iStep0',iStep0)
    -- print('New step----------')
    tLastStep=t
    plan_nextstep();
    local kick_done=myWalk.isKickDone(0);--DX
    if kick_done>0 then
      if walkKickRequest>0 then
        walkKickRequest=0
      end
    end

    -- print('uLeft1',uLeft1,'uLeft2',uLeft2)
    -- print('uRight1',uRight1,'uRight2',uRight2)
    local pack=myWalk.Xiang_walknormalloopII(step_h_cur, uLeft1, uLeft2, uRight1, uRight2, Body.get_time()-tLastStep, walkKickRequest);--TODO kick
    uLeftb=vector.new(pack[3]);
    uRightb=vector.new(pack[4]);
    uTorsob=vector.new(pack[5]);
    kick_stageb=pack[6];
    kick_doneb=pack[7];
    -- emergencyb=pack[8];
    phaseb=pack[2];

    -- print('supportLeg', supportLeg, ZMPL>0)

    -- print('kick_doneb ',kick_doneb) --DX

  else
    isnewstep=false;
  end --End new step

  --DX
  -- uTorsoDX=vector.add(vector.new(myWalk.zmp_com(ph)),uSupport)
  -- uTorso=uTorsoDX
  uTorso=uTorsob;
  uLeft=uLeftb;
  uRight=uRightb;
  uTorso[3] = 0.5*(uLeft[3]+uRight[3]) --nao leg joint is interdependent
  uTorsoActual = uTorso
  kick_stage=kick_stageb;
  kick_strike=(kick_stage==3);
  emergency=emergencyb;
  if (emergency>0) then
    stop()
    is_stopped=true
    tStopStart=t;
    tStopDuration=2
    print('emergency-----',emergency)
  end
  ph=myWalk.getPhaseLearn(0)[1];
  if kick_stage>0 then
    cp.stepHeight=0.02;

    if (kick_stage==2 ) then
      cp.stepHeight=0.03
    elseif kick_stage==3 then
      cp.stepHeight=0.043;
    end
  end
  -- if iStep<3 then
  --   cp.stepHeight=0.013
  -- end

  xFoot, zFoot = foot_phase(ph)

  if initial_step>0 then zFoot=0; end --Don't lift foot at initial step
  zLeft, zRight = 0,0
  if supportLeg == 0 then -- Left support

    local forwardL=0;
    if kick_strike then
      zRight = cp.stepHeight*zFoot
    else
      zRight = cp.stepHeight*zFoot
    end

  else -- Right support
    local forwardL=0;
    if kick_strike then

      Body.set_lleg_hardness(0.8);
      Body.set_rleg_hardness(0.8);

      zLeft = cp.stepHeight*zFoot
      -- end
    else
      -- uLeft = util.se2_interpolate(xFoot, uLeft1, uLeft2)
      zLeft = cp.stepHeight*zFoot
    end

  end
  -- print('step_h_cur',cp.stepHeight)
  pLLeg = vector.new({uLeft[1], uLeft[2], zLeft, 0,0,uLeft[3]});
  pRLeg = vector.new({uRight[1], uRight[2], zRight, 0,0,uRight[3]})

  pTorso = vector.new({uTorsoActual[1], uTorsoActual[2], cp.bodyHeight, 0,cp.bodyTilt,uTorsoActual[3]});

  -- print('pLLeg',pLLeg,'pRLeg',pRLeg)
  -- print('pLLeg[2]',pLLeg[2],'pTorso[2]',pTorso[2],'pRLeg[2]',pRLeg[2])

  local ph1Single,ph2Single = cp.phSingleRatio/2,1-cp.phSingleRatio/2
  phSingle = math.min(math.max(ph-ph1Single, 0)/(ph2Single-ph1Single),1);

  qLegs = Kinematics.inverse_legs(pLLeg, pRLeg, pTorso, supportLeg);

  -- print('hpyaw ---', qLegs[1],qLegs[7])
  -- print('qLegs',vector.new(qLegs))

  if walkKickRequest>0 then
    -- print('phSingle',phSingle,'t',t,'velCurrent',unpack(velCurrent))
  end
  ---------------------NOTE THIS IS A HUGE BUG !!!

  qLegs[7]=qLegs[1]

  ---------------------NOTE THIS IS A HUGE BUG !!!

  if ph > 0.75 then
    Body.set_actuator_hardness(0.9,9);
    Body.set_actuator_hardness(0.9,10);
    Body.set_actuator_hardness(0.9,11);
    Body.set_actuator_hardness(0.9,12);
    Body.set_actuator_hardness(0.9,15);
    Body.set_actuator_hardness(0.9,16);
    Body.set_actuator_hardness(0.9,17);
    Body.set_actuator_hardness(0.9,18);
  end

  motion_legs(qLegs);

  if usearm then
    local armswing;
    local swingmax=0.05;
    if supportLeg>0 then
      armswing=-math.cos(ph*math.pi)*velCurrent[1]*3;
    else
      armswing=-math.cos(math.pi+ph*math.pi)*velCurrent[1]*3;
    end

    Body.set_larm_command({math.pi/2+armswing,0.1,0,0})
    Body.set_rarm_command({math.pi/2-armswing,-0.1,0,0})
    Body.set_larm_hardness(0.1);
    Body.set_rarm_hardness(0.1);
  end

  uFoot = util.se2_interpolate(.5, uLeft+uLeftoff, uRight+uRightoff);
  -- print ("velCommand",unpack(velCommand))
  -- print ("velCurrent",unpack(velCurrent))

end
curstate=0;
getready_started=false;
notmoved=true;
q0_ready=Body.get_sensor_position();
t0_getready=Body.get_time();
q2=vector.zeros(22)
tdefend0=Body.get_time();
q20=q2;
function Xdive()
  if curstate==0 then
    curstate=1;
  end
end
function move2qall(q2, dur,stiff)

  -- print(unpack(q2))
  if not getready_started then
    q0_ready=Body.get_sensor_position();
    getready_started=true;
    t0_getready=Body.get_time();
    notmoved=false;
  elseif Body.get_time()-t0_getready>dur then
    getready_started=false;
    return 0;
  else

    local qcommand=vector.zeros(#q2);
    local ratio=math.min(1,(Body.get_time()-t0_getready )/dur);
    for i=1,#q2 do
      qcommand[i]=q0_ready[i]+ratio*(q2[i]-q0_ready[i]);
    end
    -- print(unpack(q2))
    Body.set_larm_command({unpack(qcommand,3,6)})
    Body.set_rarm_command({unpack(qcommand,19,22)})
    Body.set_lleg_command({unpack(qcommand,7,12)})
    Body.set_rleg_command({unpack(qcommand,13,18)})
    Body.set_head_command({unpack(qcommand,1,2)})
    Body.set_larm_hardness(stiff);
    Body.set_rarm_hardness(stiff);
    Body.set_lleg_hardness(stiff);
    Body.set_rleg_hardness(stiff);
    Body.set_head_hardness(stiff);
  end
  return 1;
end
function update()
  -- print('stopRequest',stopRequest)
  t = unix.time();
  deltaT=t-tUpdate;
  imuAngle=Body.get_sensor_imuAngle();

  if deltaT>dlt0 then
    tUpdate=t;
    t_vel_prev=t;
    vest_pitch=vel_est(imuAngle[2],deltaT,vel_pitch);
    vest_roll=vel_est(imuAngle[1],deltaT,vel_roll);
    local qs_lleg=Body.get_lleg_position();
    local qs_rleg=Body.get_rleg_position();
    qds_l=vel_est_many(qs_lleg,deltaT,vels_ql);
    qds_r=vel_est_many(qs_rleg,deltaT,vels_qr)
    diff_md=vel_est_many(diff_m,deltaT,vels_diffm)
  end

  if false then

  else
    if curstate==0  then
      normalloop();
    elseif curstate==1 then
      local q2= {-0.05832890360165,-0.65812875434202,1.3241813034881,-0.27462755780131,-1.6567537924556,-1.5508297601521,-0.95389224938498,0.27557003559738,-0.60522782471407,2.1747849677401,-1.0267073857782,-0.048136180770004,-0.95389224938498,-0.11164871225008,-0.6763150851478,2.1338919033658,-0.91156801502412,-0.063041292582035,1.2220620889539,0.27454029133871,1.4480473205021,1.4650119208315};
      -- dive
      -- local qdiveready={-0.000733,0.040131,1.239796,0.397700,-1.265500,-0.432300,-0.497607,0.003881,-1.076569,1.806685,-0.421050,-0.177667,-0.497607,-0.185293,-1.360208,1.925671,-0.485349,0.033539,1.239796,-0.397700,1.265500,0.432300}
      local qdiveready= {0.127154,0.514820,1.239796,0.397700,-1.265500,-0.432300,-1.145281,-0.259913,-1.535889,1.994141,0.038337,0.221835,-1.145281,0.144762,-1.436085,2.112540,-0.273078,-0.109169,1.239796,-0.397700,1.265500,0.432300}
      if move2qall(qdiveready, 0.3,0.5)==0 then
        curstate=2;
        tdefend0=Body.get_time();
      end
    elseif curstate==2 then
      Body.set_larm_hardness(0.4);
      Body.set_rarm_hardness(0.4);
      Body.set_lleg_hardness(0.4);
      Body.set_rleg_hardness(0.4);
      Body.set_head_hardness(0.4);
      if (Body.get_time()-tdefend0)>2 then--pause after dive
        curstate=4;
      end
    elseif curstate==4 then
      local qdiveafter={0.017245,-0.234780,1.239796,0.397700,-1.265500,-0.432300,-0.583222,0.208502,-0.772113,1.812533,-0.804694,-0.194397,-0.583098,-0.079163,-1.047451,0.853777,0.420537,0.068518,1.239796,-0.397700,1.265500,0.432300}
      if move2qall(qdiveafter, 0.8,1)==0 then
        curstate=42
      end
    elseif curstate==42 then
      local qtemp={0.092502,0.514872,1.563815,0.359538,-1.481785,-0.261799,-0.759218,0.216421,-0.965167,2.112550,-0.973894,0.158825,-0.759218,0.237365,-0.767945,1.659808,-0.277507,0.263545,1.727876,-0.006981,1.727876,0.148353}
      if move2qall(qtemp, 0.9,1)==0 then
        curstate=5
      end
    elseif curstate==5 then

      local pLLeg = vector.new({0, 0.05, 0, 0,0,0});
      local pRLeg = vector.new({0, -0.05, 0, 0,0,0})
      local pTorso = vector.new({0, 0, cp.bodyHeight, 0,cp.bodyTilt,0});
      local ql0 = Kinematics.inverse_legs(pLLeg, pRLeg, pTorso, 1);
      local q0={0,0,math.pi/2,0,0,0};
      for i=1,#ql0 do
        q0[6+i]=ql0[i]
      end
      local tmp={ math.pi/2,0,0,0};
      for i=1,#tmp do
        q0[18+i]=tmp[i]
      end
      -- q0=vector.zeros(22)
      if move2qall(q0, 1,1)==0 then
        curstate=6;
        tdefend0=Body.get_time();
      end
    elseif curstate==6 then
      if (Body.get_time()-tdefend0)>2 then--pause after dive
        curstate=0;
        tUpdate=unix.time()
      end
    end
  end

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
    qLegs=saturate_leg_joints(qLegs)
    Body.set_lleg_command(qLegs);
  end
  if deltaT>dlt0 then
    local qall=Body.get_sensor_position();
    -- comm_States(qall,qLegs)
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

function step_left_destination(vel, uLeft, uRight) --RS
  -- print('detemine step L-------------------------')--Dx mark here
  -- print('**********')
  -- print('before velCurrent[3]',velCurrent[3])
  local vel2=vector.new({vel[1],vel[2],vel[3]}); --BUG copy data this way will not impact on the original data; otherwise ...
  -- print('vel2[3]',vel2[3])

  if taf<0 then
    if vel2[3]>0 then
      vel2[3]=vel2[3]*1.33;
    else
      vel2[3]=-vel2[3]*0.33;
    end
  else
    if vel2[3]>0   then
      vel2[3]=-vel2[3]*0.33;
    else
      vel2[3]=vel2[3]*1.33;
    end
  end






  -- vel2[3]=-vel2[3];
  if vel2[2]>0 then
  else
    vel2[2]=0;
  end

  -- print('after velCurrent[3]',velCurrent[3])
  -- print('**********')

  local u0 = util.se2_interpolate(.5, uLeft, uRight);
  -- Determine nominal midpoint position 1.5 steps in future
  local u1 = util.pose_global(vel2, u0);
  local fact = 2-1.5*math.exp(-8*(0.06-math.abs(vel2[1])));

  -- print('fact ',fact)

  local u2 = util.pose_global(fact*vel2, u1); --- TODO XIANG TODO

  local uLeftPredict = util.pose_global(uLRFootOffset, u2);
  local uLeftRight = util.pose_relative(uLeftPredict, uRight);
  -- print('uLeftRight',uLeftRight)

  local deltaP=vector.new({0,0,vel2[3]/2}); --DX intermidate frame
  local uF1=util.pose_global(deltaP, uRight); --DX;--DX intermidate frame
  deltaP=vector.new({vel2[1],vel2[2],0}); --DX intermidate frame
  local uLeftPredIV=util.pose_global(deltaP+2*uLRFootOffset, uF1); --DX;--DX intermidate frame
  uLeftPredIV[3]=uLeftPredIV[3]+vel2[3]/2;
  local uLeftRightIV=util.pose_relative(uLeftPredIV, uRight);

  local uLeftPredictII = util.pose_global(1*vel2+2*uLRFootOffset, uRight); --DX
  local uLeftRightII = util.pose_relative(uLeftPredictII, uRight);
  local uLeftRightIII=vel2+2*uLRFootOffset
  --DX
  -- print('uLeftRightII',uLeftRightII)
  -- print('uLeftRightIII', uLeftRightIII)
  uLeftRight=uLeftRightIV;--dx
  -- print('uLeftRightII',uLeftRightII)--Dx mark here
  --DX debug
  -- uLeftRight[1]=0.07;
  --Check toe and heel overlap
  local toeOverlap= -footSizeX[1]*uLeftRight[3];
  local heelOverlap= -footSizeX[2]*uLeftRight[3];
  local limitY = math.max(stanceLimitY[1],
    stanceLimitY2+math.max(toeOverlap,heelOverlap));
  if taf<0 then
    uLeftRight[1] = math.min(math.max(uLeftRight[1], stanceLimitX[1]), stanceLimitX[2]);
    uLeftRight[2] = math.min(math.max(uLeftRight[2], limitY),stanceLimitY[2]);
    uLeftRight[3] = math.min(math.max(uLeftRight[3], stanceLimitA[1]), stanceLimitA[2]);
  end
  -- print('deltaP+2*uLRFootOffset',deltaP+2*uLRFootOffset)
  -- print('uLeftRight[3]',uLeftRight[3])
  return util.pose_global(uLeftRight, uRight);
end

function step_right_destination(vel, uLeft, uRight)--LS
  -- print('detemine step R-------------------------')--Dx mark here
  local vel2=vector.new({vel[1],vel[2],vel[3]});
  -- print('vel2[3]',vel2[3])
  if taf<0 then
    if vel2[3]<0 then
      vel2[3]=vel2[3]*1.33;
    else
      vel2[3]=-vel2[3]*0.33;
    end
  else
    if vel2[3]<0   then
      vel2[3]=-vel2[3]*0.33;
    else
      vel2[3]=vel2[3]*1.33;
    end
  end


    -- vel2[3]=-vel2[3];

    if vel2[2]<0 then
    else
      vel2[2]=0;
    end

  local u0 = util.se2_interpolate(.5, uLeft, uRight);
  -- Determine nominal midpoint position 1.5 steps in future
  local u1 = util.pose_global(vel2, u0);
  local fact = 2-1.5*math.exp(-8*(0.06-math.abs(vel2[1])));

  local u2 = util.pose_global(fact*vel2, u1); --- TODO XIANG TODO
  local uRightPredict = util.pose_global(-1*uLRFootOffset, u2);
  local uRightLeft = util.pose_relative(uRightPredict, uLeft);

  -- print('1*vel-2*uLRFootOffset',1*vel2-2*uLRFootOffset)
  local uRightPredictII = util.pose_global(1*vel2-2*uLRFootOffset, uLeft); --DX
  local uRightLeftII = util.pose_relative(uRightPredictII, uLeft);
  local uRightLeftIII=vel2-2*uLRFootOffset;
  -- print('uRightLeftII',uRightLeftII)
  -- print('uRightLeftIII', uRightLeftIII)

  local aM=(uLeft[3]+vel2[3]+uLeft[3])/2;
  local deltaP=vector.new({0,0,vel2[3]/2}); --DX intermidate frame
  local uF1=util.pose_global(deltaP, uLeft); --DX;--DX intermidate frame
  deltaP=vector.new({vel2[1],vel2[2],0}); --DX intermidate frame
  local uRightPredIV=util.pose_global(deltaP-2*uLRFootOffset, uF1); --DX;
  uRightPredIV[3]=uRightPredIV[3]+vel2[3]/2;
  local uRightLeftIV=util.pose_relative(uRightPredIV, uLeft);

  -- print('uRightLeftII[3]',uRightLeftII[3],'uLeft[3]',uLeft[3])
  uRightLeft=uRightLeftIV;--dx
  -- print('uRightLeftII',uRightLeftII)--Dx mark here

  --DX debug    print('notswap ',notswap)
    -- print('iStep ',iStep,'iStep0',iStep0)
    -- print('New step----------')
  -- uRightLeft[1]=0.07;
  --Check toe and heel overlap
  local toeOverlap= footSizeX[1]*uRightLeft[3];
  local heelOverlap= footSizeX[2]*uRightLeft[3];
  local limitY = math.max(stanceLimitY[1],
    stanceLimitY2+math.max(toeOverlap,heelOverlap));
  if taf<0 then
    uRightLeft[1] = math.min(math.max(uRightLeft[1], stanceLimitX[1]), stanceLimitX[2]);
    uRightLeft[2] = math.min(math.max(uRightLeft[2], -stanceLimitY[2]), -limitY);
    uRightLeft[3] = math.min(math.max(uRightLeft[3], -stanceLimitA[2]), -stanceLimitA[1]);
  end
  return util.pose_global(uRightLeft, uLeft);
end

function step_torso(uLeft, uRight,shiftFactor)
  local u0 = util.se2_interpolate(.5, uLeft, uRight);
  -- print('cp.supportY',cp.supportY)
  local uLeftSupport = util.pose_global({cp.supportX, cp.supportY, 0}, uLeft);
  local uRightSupport = util.pose_global({cp.supportX, -cp.supportY, 0}, uRight);
  -- print('cp.supportX ',cp.supportX,' cp.supportY ',cp.supportY)
  return util.se2_interpolate(shiftFactor, uLeftSupport, uRightSupport);
  -- return u0;
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

  -- velCommand[1],velCommand[2],velCommand[3]=
  -- velCommand[1],velCommand[2],velCommand[3]=vx*magFactor,vy*magFactor,va;
  -- velCommand[1],velCommand[2],velCommand[3]=(vx)/(stepMag+0.00001),(vy)/(stepMag+0.00001),va
  velCommand[1],velCommand[2],velCommand[3]=vx,vy,va
  -- velCommand[1] = math.min(math.max(velCommand[1],velLimitX[1]),velLimitX[2]);
  -- velCommand[2] = math.min(math.max(velCommand[2],velLimitY[1]),velLimitY[2]);
  -- velCommand[3] = math.min(math.max(velCommand[3],velLimitA[1]),velLimitA[2]);
  -- print('velCommand',velCommand[1],velCommand[2],velCommand[3])
end

function update_velocity()
  -- print('--------------------------')
  -- print('velCurrent[3] ', velCurrent[3],'velCommand[3] ', velCommand[3])
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

  for i=1,2 do
    local ff=1;
    if math.abs(velCommand[i])<0.01 then
      ff=1;
    else
      ff=0.3;
    end
    velCurrent[i] = velCurrent[i]+ff*velDiff[i]
  end

  local velnorm=math.sqrt(velCurrent[1]*velCurrent[1]+velCurrent[2]*velCurrent[2])

  local fact1=1;
  if velCurrent[1]<0 then
    fact1=-1;
  end
  velCurrent[1]=math.min(math.abs(velCurrent[1]),0.045)*fact1;

  local fact2=1;
  if velCurrent[2]<0 then
    fact2=-1;
  end
  velCurrent[2]=math.min(math.abs(velCurrent[2]),0.07)*fact2;

  -- print('velCommand[3]',velCommand[3])
  velCurrent[3] = velCurrent[3]+0.3*velDiff[3]
  -- print('velCurrent[3]',velCurrent[3],'velDiff[3]',velDiff[3])
  -- velCurrent[3]=0.6 --DX

  if math.abs(velCommand[1])<0.005 then
    velCurrent[1]=0;
  end

  if math.abs(velCommand[2])<0.005 then
    velCurrent[2]=0;
  end

  if math.abs(velCurrent[3])<0.01 then
    velCurrent[3]=0;
  end
  local robotName = unix.gethostname();

  -- velCurrent[1]=0.04;--DX
  if initial_step>0 then
    velCurrent=vector.new({0,0,0})
    initial_step=initial_step-1
  end

  if not active then
    velCurrent=vector.new({0,0,0})--DX
  end

  myWalk.setvelCurrent(velCurrent)
end

function get_velocity() return velCurrent end


function doWalkKickLeft()
  if walkKickRequest==0 then
    walkKickRequest = 1;
    kicksign=1;
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
    kicksign=-1;
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
    walkKick = walkKickDef["FrontRight2"]
   end
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

  function stopAlign() stop() end

  function stance_reset() --standup/sitdown/falldown handling
    print("Stance Resetted")
    uLeft = util.pose_global(vector.new({-cp.supportX, cp.footY, 0}),uTorso)
    uRight = util.pose_global(vector.new({-cp.supportX, -cp.footY, 0}),uTorso)
    uLeft1, uLeft2,uRight1, uRight2,uTorso1, uTorso2 = uLeft, uLeft, uRight, uRight, uTorso, uTorso
    uSupport = uTorso
    -- tLastStep=Body.get_time()
    walkKickRequest = 0
    -- iStep0,iStep = 0,0 --DX
    -- istep0=istep;
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

  function calculate_swap()
    if (not Config.walk.variable_step) or Config.walk.variable_step==0 then
      return Config.walk.tStep
    end
    if true then
      return cp.tStep
    end

  end
  function foot_phase(ph)
    -- Computes relative x,z motion of foot during single support phase
    -- phSingle = 0: x=0, z=0, phSingle = 1: x=1,z=0
    -- print('phSingleRatio ',cp.phSingleRatio)
    local ph1Single,ph2Single = cp.phSingleRatio/2,1-cp.phSingleRatio/2
    phSingle = math.min(math.max(ph-ph1Single, 0)/(ph2Single-ph1Single),1);
    local phSingleSkew = phSingle^0.8 - 0.17*phSingle*(1-phSingle);
    local xf = .5*(1-math.cos(math.pi*phSingleSkew));
    local zf = .5*(1-math.cos(2*math.pi*phSingleSkew));
    -- return xf, zf

    -- print('phSingle',phSingle,'xf',xf)
    ----------- try parabola as RS
    local xh=0;
    local zh=0;
    if phSingle < 0.25 then
      zh=8*phSingle*phSingle;
    elseif phSingle >=0.25 and phSingle < 0.5 then
      xh=0.5-phSingle;
      zh=1-8*xh*xh;
    elseif phSingle >=0.5 and phSingle < 0.75 then
      xh=phSingle-0.5;
      zh=1-8*xh*xh;
    else
      xh=1-phSingle;
      zh=8*xh*xh;
    end

    local xh=0;
    if phSingle<0.5 then
      xh=2*phSingle*phSingle;
    else
      xh=4*phSingle-2*phSingle*phSingle-1;
    end

    if not kick_strike then
      return xh,zh
    else
      return xf,zh
    end
    ------------------------------------
  end
