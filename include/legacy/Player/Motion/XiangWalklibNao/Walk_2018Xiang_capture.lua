---Author of correspondence for locomotion 2018:
-- Xiang Deng, dxiang@seas.upenn.edu
module(..., package.seeall);
--
require "zhelpers"
local zmq = require "lzmq"

-- Prepare our context and publisher
local context = zmq.context()
local publisher, err = context:socket{zmq.PUB, bind = "tcp://*:5564"}
zassert(publisher, err)
local subscriber, err = context:socket{zmq.SUB,
  subscribe = "control_msg";
  connect = "tcp://192.168.123.99:5563";
}
zassert(subscriber, err)
print('lmzq setup',zmq);
function comm_States(qLeg_command,qall,ss,vxvy,ZMPL,ZMPFl,ZMPFr,dt, ph,com2pos1opos2o,imuAngle)

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
  send_message=send_message.."|"..ss[7];
  send_message=send_message.."|"..ZMPL;
  send_message=send_message.."|"..ZMPFl;
  send_message=send_message.."|"..ZMPFr;
  send_message=send_message.."|"..dt;
  send_message=send_message.."|"..ph;
  send_message=send_message.."|"..ss[2];
  send_message=send_message.."|"..vxvy[2];
  send_message=send_message.."|"..ss[1];
  send_message=send_message.."|"..vxvy[1];
  for i=1,6 do
    send_message=send_message.."|"..com2pos1opos2o[i];
  end
  for curr_id=1,#qLeg_command do
    cur_pos= qLeg_command[curr_id];
    cur_pos=rounddeci(cur_pos,5);
    send_message=send_message.."|"..cur_pos;
  end
  for i=1,3 do
    send_message=send_message.."|"..imuAngle[i];
  end
  publisher:sendx(send_message);
end
function rounddeci(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end
function rounddeci_vec(qs, numDecimalPlaces)
  for j=1,#qs do
    qs[j]=rounddeci(qs[j],3)
  end
  return qs
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
-- tUpdate = unix.time();
t = Body.get_time();
tUpdate = Body.get_time();
useLearner=true;
tau_lrn=0.25;
step_height_lrn=0.023;
com_height_lrn=0.31;
ph=0;

useSerial=true;
usewebots=false;
logdata=false;
dlt0=0.02;
useremote1=false;
dontmove=false;
usetoesupport=false;
leftkick=false;
kickcommandpause=false;
unlock_kick=0;
uLeftoff = vector.new({0, 0, 0});
uRightoff = vector.new({0, 0, 0});
uTorsooff=vector.new({0, 0, 0});
uTorso = vector.new({Config.walk.supportX, 0, 0});
uLeft = vector.new({0, Config.walk.footY, 0});
uRight = vector.new({0, -Config.walk.footY, 0});
velCurrent, velCommand,velDiff = vector.new({0,0,0}),vector.new({0,0,0}),vector.new({0,0,0})
velLimitX = {-.02, .04};--Config.walk.velLimitX or {-.06, .1};
velLimitY = {-.08, .08};
velLimitA = {-.6, .6};--Config.walk.velLimitA or
velDelta = Config.walk.velDelta or {.03,.015,.15};
vaFactor = Config.walk.velLimitA[2] or 0.6;
velXHigh = Config.walk.velXHigh or 0.06;
velDeltaXHigh = Config.walk.velDeltaXHigh or 0.01;
uFoot = vector.zeros(3)
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
myWalk=require('liblibNAOWalk')

for i=1,100 do
  print('Config.walk.footX',Config.walk.footX)
end

s_getup=0;
qcontrol=vector.zeros(22);

-- diff_m=vector.zeros(3);
-- diff_md=vector.zeros(3);

nJoints=22;

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
-----------------------------------------------------

imuAngle=Body.get_sensor_imuAngle();
qall=Body.get_sensor_position();

cnt=0;
-- curstate: 0: relax, do nothing; 1: goto frame before getup; 2: getup; 3: tmpframe; 99: don't move

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

filteredGyroY=0;

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

--Gyro stabilization parameters
ankleImuParamX = Config.walk.ankleImuParamX;
ankleImuParamY = Config.walk.ankleImuParamY;
kneeImuParamX = Config.walk.kneeImuParamX;
hipImuParamY = Config.walk.hipImuParamY;
--Gyro stabilization variables
ankleShift,kneeShift,hipShift,toeTipCompensation = vector.new({0,0}),0,vector.new({0,0}),0
function motion_legs(supportLeg,qLegs,gyro_off)

  --Ankle stabilization using gyro feedback
  imuGyr = Body.get_sensor_imuGyrRPY();
  gyro_roll0,gyro_pitch0=imuGyr[1],imuGyr[2]
  if gyro_off then gyro_roll0,gyro_pitch0=0,0 end

  --get effective gyro angle considering body angle offset

  yawAngle=0;
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

  if false then --Double support, standing still
    qLegs[4] = qLegs[4] + kneeShift; --Knee pitch stabilization
    qLegs[5] = qLegs[5] + ankleShift[1]; --Ankle pitch stabilization
    qLegs[10] = qLegs[10] + kneeShift; --Knee pitch stabilization
    qLegs[11] = qLegs[11] + ankleShift[1]; --Ankle pitch stabilization

  elseif supportLeg < 0 then -- Left support
    qLegs[2] = qLegs[2] + hipShift[2]; --Hip roll stabilization
    qLegs[4] = qLegs[4] + kneeShift; --Knee pitch stabilization
    qLegs[5] = qLegs[5] + ankleShift[1]; --Ankle pitch stabilization
    qLegs[6] = qLegs[6] + ankleShift[2]; --Ankle roll stabilization
  else
    qLegs[8] = qLegs[8] + hipShift[2]; --Hip roll stabilization
    qLegs[10] = qLegs[10] + kneeShift; --Knee pitch stabilization
    qLegs[11] = qLegs[11] + ankleShift[1]; --Ankle pitch stabilization
    qLegs[12] = qLegs[12] + ankleShift[2]; --Ankle roll stabilization

  end
  return qLegs;

end

getready_started=false;
notmoved=true;
q0_ready=Body.get_sensor_position();
t0_getready=Body.get_time();
q2=vector.zeros(22)
q20=q2;
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
curstate=-1;
function set_state(si)
  curstate=si;
  print('================curstate',curstate)
end

t_istep=Body.get_time();
function update()

  imuAngle=Body.get_sensor_imuAngle();
  if usewebots then
    imuAngle[2]=-imuAngle[2];
    -- imuGyr[2]=-imuGyr[2]
  end
  if (math.abs(imuAngle[2])<0.3) and curstate==1 then
    Body.set_larm_hardness(1);
    Body.set_rarm_hardness(1);
    Body.set_lleg_hardness(1);
    Body.set_rleg_hardness(1);
    Body.set_head_hardness(1);
    curstate=-1;
  elseif curstate==0 then
    -- sit
    local q2= {-0.05832890360165,-0.65812875434202,1.3241813034881,-0.27462755780131,-1.6567537924556,-1.5508297601521,-0.95389224938498,0.27557003559738,-0.60522782471407,2.1747849677401,-1.0267073857782,-0.048136180770004,-0.95389224938498,-0.11164871225008,-0.6763150851478,2.1338919033658,-0.91156801502412,-0.063041292582035,1.2220620889539,0.27454029133871,1.4480473205021,1.4650119208315};
    -- dive
    -- local qdiveready={-0.000733,0.040131,1.239796,0.397700,-1.265500,-0.432300,-0.497607,0.003881,-1.076569,1.806685,-0.421050,-0.177667,-0.497607,-0.185293,-1.360208,1.925671,-0.485349,0.033539,1.239796,-0.397700,1.265500,0.432300}
    local qdiveready= {0.127154,0.514820,1.239796,0.397700,-1.265500,-0.432300,-1.145281,-0.259913,-1.535889,1.994141,0.038337,0.221835,-1.145281,0.144762,-1.436085,2.112540,-0.273078,-0.109169,1.239796,-0.397700,1.265500,0.432300}
    if move2qall(qdiveready, 0.3,0.4)==0 then

      curstate=2;
      tdefend0=Body.get_time();
    end
  elseif curstate==1 then
    Body.set_larm_hardness(0);
    Body.set_rarm_hardness(0);
    Body.set_lleg_hardness(0);
    Body.set_rleg_hardness(0);
    Body.set_head_hardness(0);
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
  elseif curstate==41 then
    local qtemp={-0.090463,-0.666741,1.239796,0.397700,-1.265500,-0.432300,-0.187852,0.672597,-1.083440,2.111979,-1.115528,-0.397761,-0.187870,-0.753429,-1.534873,1.125023,0.335132,0.397761,1.239796,-0.397700,1.265500,0.432300}
    if move2qall(qtemp, 0.3,1)==0 then
      curstate=42
    end
  elseif curstate==42 then
    local qtemp={0.092502,0.514872,1.563815,0.359538,-1.481785,-0.261799,-0.759218,0.216421,-0.965167,2.112550,-0.973894,0.158825,-0.759218,0.237365,-0.767945,1.659808,-0.277507,0.263545,1.727876,-0.006981,1.727876,0.148353}
    if move2qall(qtemp, 0.7,1)==0 then
      curstate=5
    end
  elseif curstate==5 then
    if move2qall(q2, 0.7,1)==0 then
      curstate=6;
    end
  elseif curstate==6 then
    if (Body.get_time()-tdefend0)>6 then
      curstate=-1;
    end
  elseif notmoved then
    t_istep=Body.get_time();
    ---------------------------------------
    myWalk.LIPMLearnerforward(0)
    local qs=myWalk.LIPMLearner_computeLegJoints(0);

    q2={0,0,math.pi/2,0,0,0};
    for i=1,#qs do
      q2[6+i]=qs[i]
    end
    local tmp={ math.pi/2,0,0,0};
    for i=1,#tmp do
      q2[18+i]=tmp[i]
    end

    move2qall(q2,2,0.5)
    q20=q2;

    -------------------------------------------
  elseif getready_started then
    move2qall(q2,2,1)
  else
    if cnt==0 then
      t=Body.get_time();
    end
    cnt=cnt+1;
    -- t = unix.time();
    local tcur=Body.get_time();
    -- print('t',t)
    deltaT=tcur-t;
    if deltaT<0.005 then
      return
    end
    t=tcur;
    -- print('deltaT',deltaT)
    imuAngle=Body.get_sensor_imuAngle();
    imuGyr = Body.get_sensor_imuGyr();
    -- print(unpack(imuAngle))
    qall=Body.get_sensor_position();
    if usewebots then
      imuAngle[2]=-imuAngle[2];
      -- imuGyr[2]=-imuGyr[2]
    end

    if (math.abs(imuAngle[2])>0.7) then
      curstate=1; ----falling, end walk
    end
    imuAngle[3]=0;
    computeZMPfromSensor();
    local tau=myWalk.getTau(0);
    -- print('tau',unpack(tau))
    -- print(ZMPFl,ZMPFr)
    if (lastZMPL*ZMPL<0) then
      local tstep=Body.get_time()-t_istep;
      t_istep=Body.get_time();
      -- myWalk.resetStep(0);
      print('---------',ss[8],'----',t_istep)
    end

    -- local ph=0;
    if useLearner then
      myWalk.LIPMLearnerforward(deltaT)
      qs=myWalk.LIPMLearner_computeLegJoints(0);
      ph=myWalk.getPhaseLearn(0)[1];
    else
      myWalk.forward(deltaT)
      qs=myWalk.computeLegJoints(0);
      ph=myWalk.getPhaseWalk(0)[1];
    end
    gyro_roll0,gyro_pitch0=imuGyr[1],imuGyr[2]
    filteredGyroY = 0.9 * filteredGyroY + 0.1 *gyro_pitch0;
    -- print('filteredGyroY',filteredGyroY)
    local istep=myWalk.getistep(0)[1];
    local signi=myWalk.getsigni(0)[1];
    ss=myWalk.getCurrentXYandPhase(0);
    local qlleg={unpack(qall,7,12)};
    local qrleg={unpack(qall,13,18)};
    local qlarm={unpack(qall,3,6)};
    local qrarm={unpack(qall,19,22)};
    local qhead={unpack(qall,1,2)};
    -- print(ss[2])
    if istep>1 then
      myWalk.setZMPL(ZMPL);
      myWalk.set_estimate_state(imuAngle,qhead,qlleg,qrleg,qlarm,qrarm,deltaT);
      -- print(velCommand)
      -- if (velCommand[1]==0 and velCommand[2]==0 and velCommand[3]==0) then
      -- myWalk.reset_vel_cmmd(0);
      -- print('here')
      -- else
      myWalk.set_szxL_delta(velCommand[1]);
      myWalk.set_szxR_delta(velCommand[1]);
      myWalk.set_szy_delta(velCommand[2]);
      myWalk.set_turn(velCommand[3]);
      -- end
    end

    local vxvy=myWalk.getVxVy(0);
    local com2pos1opos2o=myWalk.getAbsCOM2FootContacts(0);
    -- qs=myWalk.footStepdownExperiment(0);
    -- print('ph',ph)
    comm_States(qs,qall,ss,vxvy, ZMPL,ZMPFl,ZMPFr,deltaT,ph,com2pos1opos2o,imuAngle)

    Body.set_larm_hardness(0.3);
    Body.set_rarm_hardness(0.3);
    if signi>0 then--rs
      Body.set_rleg_hardness(0.9);
      Body.set_lleg_hardness(0.7);
    else
      Body.set_lleg_hardness(0.9);
      Body.set_rleg_hardness(0.7);
    end




    Body.set_head_hardness(0.5);
    -- print('---ss--------',deltaT)
    rounddeci_vec(ss,3)
    rounddeci_vec(qs,3)
    -- print(unpack(ss))
    -- print(unpack(qs))

    -- stabilization using gyro feedback

    -- print(filteredGyroY)
    -- filteredGyroY=0;
    if filteredGyroY<10 then
      filteredGyroY=filteredGyroY*0.1
    end
    if istep>10 and true then
      if signi>0 then --rs
        qs[11] = qs[11] + filteredGyroY/400; --Ankle pitch stabilization
      else
        qs[5] = qs[5] + filteredGyroY/400; --Ankle pitch stabilization
      end
    end
    filteredGyroY=filteredGyroY*0.1;

    local armswing;
    local swingmax=0.05;
    if signi>0 then
      armswing=-math.cos(ph*math.pi)*myWalk.getLarmSwingAmp(0)[1];
    else
      armswing=-math.cos(math.pi+ph*math.pi)*myWalk.getRarmSwingAmp(0)[1];
    end

    -- qs=motion_legs(signi,qs,true)
    -- armswing=0;
    -- print(armswing)
    local kp=0.2;
    for i=1,4 do
      qs[i]=qs[i]+(qs[i]-qlleg[i])*kp;
    end
    for i=1,4 do
      qs[6+i]=qs[6+i]+(qs[6+i]-qrleg[i])*kp;
    end
    Body.set_larm_command({math.pi/2+armswing,0.2,0,0})
    Body.set_rarm_command({math.pi/2-armswing,-0.2,0,0})
    Body.set_lleg_command({unpack(qs,1,6)})
    Body.set_rleg_command({unpack(qs,7,12)})
    Body.set_head_command({0,0})
  end
end

collectnew=false;
canWalkKick = true;
function doWalkKickLeft()
  -- collectnew=true;
  myWalk.kickLeft(0);
end
function doWalkKickRight()
  -- collectnew=true;
  myWalk.kickRight(0);
end
function doWalkKickLeft2()
  myWalk.kickLeft(0);
end
function doWalkKickRight2()
  myWalk.kickRight(0);
end
function exit() end
function entry()
  myWalk=require('liblibNAOWalk')
  myWalk.init(0);

  if useLearner then
    myWalk.LIPMLearnerInit(tau_lrn,step_height_lrn,com_height_lrn)
  end
  print ("Motion: Walk 2018 capture entry")
end
function update_still()
end
function start()
  stopRequest = 0;
  if (not active) then
    active = true
    started = false
    iStep0 = -1
    tLastStep = Body.get_time()
    initial_step=2
    myWalk.resume(0);
  end
end
function stop()
  myWalk.stop(0);
  active=false;
end
function stance_reset()
end
function get_body_offset()---DX TODO fix odometry for localization!
  --in motion.lua update_shm needs:
  -- mcm.set_walk_bodyOffset(walk.get_body_offset());
  -- mcm.set_walk_uLeft(walk.uLeft);
  -- mcm.set_walk_uRight(walk.uRight);
  -- mcm.set_walk_uFoot(walk.uFoot);
  -- --> mcm.get_odometry-->World for localization
  local uFoot = util.se2_interpolate(.5, uLeft+uLeftoff, uRight+uRightoff);
  local odo= util.pose_relative(uTorso+uTorsooff, uFoot);

  ---TODO update uFoot
  -- print('get_odometry walk------', odo)
  return odo;
end
function set_maxvel(vx,vy,va)
local vx,vy,va = vx,vy,va;
local min = 0.2; local xmax = 0.5;local ymax = 0.8; local amax = 0.9;
local yval = 0.001; local xval = 0.02;
local aval = 0.05;
if vx < 0 then
 vx = vx*xmax; vy = vy*min; va = va*min;
 if (math.abs(vy)<yval) then
   vy = 0;
 end
 if (math.abs(va)<aval) then
   va = 0;
 end
elseif (math.abs(vx)> math.abs(vy) )and (math.abs(vx) > math.abs(va)) then
 vx = vx*xmax; vy = vy*min; va = va*min;
 if (math.abs(va)<aval) then
   va = 0;
 end
 if (math.abs(vy)<yval) then
   vy = 0;
 end
elseif (math.abs(vy) > math.abs(vx)) and (math.abs(vy) > math.abs(va)) then
vx = vx*min; vy = vy*ymax; va = va*min; if (math.abs(vx)<xval) then
   vx = 0;
 end
 if (math.abs(va)<aval) then
   va = 0;
 end elseif (math.abs(va) > math.abs(vx)) and (math.abs(va) > math.abs(vy) )then
 vx = vx*min; vy = vy*min; va = va*amax;
 if (math.abs(vx)<xval) then
   vx = 0;
 end
 if (math.abs(vy)<yval) then
   vy = 0;
 end end

 local maxX=0.03;
 local maxY=0.05;
 local maxA=0.4;
 vx = math.max(-maxX, math.min(maxX, vx));
 vy = math.max(-maxY, math.min(maxY, vy));
 va = math.max(-maxA, math.min(maxA, va));
return vx,vy,va
end
function set_velocity(vx, vy, va)
  --Filter the commanded speed
  vx= math.min(math.max(vx,velLimitX[1]),velLimitX[2]);
  vy= math.min(math.max(vy,velLimitY[1]),velLimitY[2]);
  va= math.min(math.max(va,velLimitA[1]),velLimitA[2]);
  vx,vy,va=set_maxvel(vx,vy,va)
  -- print('velLimitY[1]',velLimitY[1],'velCommand[2]',velCommand[2])
  --Slow down when turning
  vFactor = 1-math.abs(va)/vaFactor;

  local stepMag=math.sqrt(vx^2+vy^2);
  local magFactor=math.min(velLimitX[2]*vFactor,stepMag)/(stepMag+0.000001);
  magFactor=1;
  -- velCommand[1],velCommand[2],velCommand[3]=
  velCommand[1],velCommand[2],velCommand[3]=vx*magFactor,vy*magFactor,va;

  velCommand[1] = math.min(math.max(velCommand[1],velLimitX[1]),velLimitX[2]);
  velCommand[2] = math.min(math.max(velCommand[2],velLimitY[1]),velLimitY[2]);
  velCommand[3] = math.min(math.max(velCommand[3],velLimitA[1]),velLimitA[2]);
  if (math.abs(velCommand[3])<0.01) then
    velCommand[3]=0;
  end
end
entry()
