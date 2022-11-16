-- Deng,Xiang dxiang@seas.upenn.edu 
--- borrowed some from run_test_walk.lua


cwd = cwd or os.getenv('PWD')
package.path = cwd.."/?.lua;"..package.path;

 ---------lzmq======================================
require "zhelpers"
local zmq = require "lzmq"
-- Prepare our context and publisher
local context = zmq.context()
local publisher, err = context:socket{zmq.PUB, bind = "tcp://*:5564"}
zassert(publisher, err)
local subscriber, err = context:socket{zmq.SUB,
  subscribe = "control_msg";
  connect   = "tcp://192.168.123.99:5563";
}
zassert(subscriber, err)
print('lmzq setup',zmq);
-- =================================================
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




require('init')
require('Config');
require('shm')
require('Body')
require('vector')
require('getch')
require('Motion');
require('walk');
require('dive');
require('Speak')
require('util')

local matrix = require('matrix');
 

darwin = false;
webots = false;
init = false;
calibrating=false;
ready=false;

getch.enableblock(1);

-- initialize state machines
Motion.entry();
--Motion.event("standup");

Body.set_head_hardness({0.4,0.4});

-- main loop

lcount=0

count = 0;
vcmcount=0;
local t0=Body.get_time();
local last_update_time=t0;
local headangle=vector.new({0,10*math.pi/180});
local headsm_running=0;
local bodysm_running=0;
local last_vision_upfasfdsaasfgate_time=t0;
targetvel=vector.zeros(3);
t_update=2;

Motion.fall_check=0;
--Motion.fall_check=1;
broadcast_enable=0;
ballcount,visioncount,imagecount=0,0,0;
hires_broadcast=0;

cameraparamcount=1;
broadcast_count=0;
buttontime=0;

paramsets={
--Name default div min
	{"bodyHeight",Config.walk.bodyHeight,0.005, 0.25},
	{"footY",Config.walk.footY,0.005, 			0.04},
	{"supportX",Config.walk.supportX,0.005, 	0},
	{"tStep",Config.walk.tStep,0.005,			0.24},
	{"supportY",Config.walk.supportY,0.005,		0},
	{"tZmp",Config.walk.tZmp,0.0025,			0.15},
	{"stepHeight",Config.walk.stepHeight,0.00125,	0.01},
	{"phSingleRatio",Config.walk.phSingleRatio,0.01,	0.01},
	{"hardnessSupport",Config.walk.hardnessSupport,0.05, 0.3},
	{"hardnessSwing",Config.walk.hardnessSwing,0.05, 	0.3},
	{"hipRollCompensation",Config.walk.hipRollCompensation,0.005, 0},
	{"zmp_type",Config.walk.zmp_type,1, 0},
}

currentparam = 1
print('lmzq check',zmq);

tUpdate = unix.time();
      local qLLeg = Body.get_lleg_position();
      local qRLeg = Body.get_rleg_position(); 
      print('deltaT ',deltaT) 
      print('lleg') 
      print(unpack(qLLeg))
      print('rleg')
      print(unpack(qRLeg))    
      for i=1,6 do
        qLLeg[i] = 0;
        qRLeg[i] = 0;    
      end 

      qLArm={};
      qRArm={};
      for i=1,4 do
        qLArm[i] = 0;
        qRArm[i] = 0;    
      end   
      qLArm[1]= 90/180*math.pi;
      qRArm[1]= 90/180*math.pi;    
      Body.set_larm_command(qLArm);
      Body.set_rarm_command(qRArm);
      Body.set_larm_hardness(.1);
      Body.set_rarm_hardness(.1);
      Body.set_head_command({0.2,0});
      Body.set_head_hardness(0.1);      
      unix.usleep(1000000);
      ---<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>
      --- see player/lib/NaoBody.lua -----------
      Body.set_lleg_command(qLLeg);
      Body.set_rleg_command(qRLeg);   
      Body.set_lleg_hardness(0.4);
      Body.set_rleg_hardness(0.4);
      qLLeg_prev=qLLeg;
      qRLeg_prev=qRLeg; 
--Hack for saffire


function process_keyinput()
--  local str = controller.wb_robot_keyboard_get_key();
  local str = getch.get()
  if #str>0 then 
  	byte = string.byte(str,1)

		if byte==string.byte("q") then	
		  currentparam = (currentparam+(#paramsets-2)) %(#paramsets)+1

		  print(string.format("%s : %.5f",paramsets[currentparam][1],Config.walk[paramsets[currentparam][1]]))
		elseif byte==string.byte("w") then			
			print(string.format("%s : %.5f",paramsets[currentparam][1],Config.walk[paramsets[currentparam][1]]))
		elseif byte==string.byte("e") then			
			currentparam = currentparam %(#paramsets)+1
		  print(string.format("%s : %.5f",paramsets[currentparam][1],Config.walk[paramsets[currentparam][1]]))
		elseif byte==string.byte("[") then	
			Config.walk[paramsets[currentparam][1]]=
			math.max(paramsets[currentparam][4],
				Config.walk[paramsets[currentparam][1]]-paramsets[currentparam][3]
				)	
			print(string.format("%s : %.5f",paramsets[currentparam][1],Config.walk[paramsets[currentparam][1]]))

		elseif byte==string.byte("]") then	
			Config.walk[paramsets[currentparam][1]]=
				math.max(paramsets[currentparam][4],
				Config.walk[paramsets[currentparam][1]]+paramsets[currentparam][3]
				)	
			print(string.format("%s : %.5f",paramsets[currentparam][1],Config.walk[paramsets[currentparam][1]]))

		elseif byte==string.byte("1") then	kick.set_kick("kickForwardLeft"); Motion.event("kick");
		elseif byte==string.byte("2") then	 kick.set_kick("kickForwardRight"); Motion.event("kick");
		elseif byte==string.byte("3") then  walk.doStepKickLeft();
		elseif byte==string.byte("4") then  walk.doStepKickRight();
	  elseif byte==string.byte("5") then  walk.doWalkKickLeft();
	  elseif byte==string.byte("6") then  walk.doWalkKickRight();
	  elseif byte==string.byte("t") then  walk.doSideKickLeft();
	  elseif byte==string.byte("y") then  walk.doSideKickRight();
	  elseif byte==string.byte("7") then	Motion.event("sit");
		elseif byte==string.byte("8") then	
			if walk.active then walk.stop() end
			Motion.event("standup")
		elseif byte==string.byte("9") then	Motion.event("walk"); walk.start()
		  
    else
			-- Walk velocity setting
			if byte==string.byte("i") then	targetvel[1]=targetvel[1]+0.02;
			elseif byte==string.byte("j") then	targetvel[3]=targetvel[3]+0.1;
			elseif byte==string.byte("k") then	targetvel[1],targetvel[2],targetvel[3]=0,0,0;
			elseif byte==string.byte("l") then	targetvel[3]=targetvel[3]-0.1;
			elseif byte==string.byte(",") then	targetvel[1]=targetvel[1]-0.02;
			elseif byte==string.byte("h") then	targetvel[2]=targetvel[2]+0.02;
			elseif byte==string.byte(";") then	targetvel[2]=targetvel[2]-0.02;
		  end
			walk.set_velocity(unpack(targetvel));
--			print("Command velocity:",walk.velCommand[1],walk.velCommand[2],walk.velCommand[3]*180/math.pi)
		end
	end

end



function update()
  count = count + 1;
  --Update battery info
  wcm.set_robot_battery_level(Body.get_battery_level());
  --Set game state to SET to prevent particle resetting
  gcm.set_game_state(1);

  if (not init)  then
    if (calibrating) then
      if (Body.calibrate(count)) then
        Speak.talk('Calibration done');
        calibrating = false;
        ready = true;
      end
    elseif (ready) then
      init = true;
    else
      if (count % 20 == 0) then
--start calibrating without waiting 
--        if (Body.get_change_state() == 1) then
          Speak.talk('Calibrating');
          calibrating = true;
--        end
      end
      -- toggle state indicator
      if (count % 100 == 0) then
        initToggle = not initToggle;
        if (initToggle) then
          Body.set_indicator_state({1,1,1}); 
        else
          Body.set_indicator_state({0,0,0});
        end
      end
    end
  else
    -- update state machines 
    process_keyinput();    
    Motion.update();
    Body.update();
 

  end

  local q_command=Body.get_command_angles();

  -----------------LZMQ routine----------------
  t = unix.time();
  deltaT=t-tUpdate;
  if deltaT>0.02 and ready then
      tUpdate = t;
      -------get control---------
        local control_contents = subscriber:recvx();
        control_pkg=mysplit(control_contents,'|');
      ---------------------------


      local qLLeg = Body.get_lleg_position();
      local qRLeg = Body.get_rleg_position(); 
      qLLegdot={};qRLegdot={};
      for i=1,6 do
        qLLegdot[i]=(qLLeg[i]-qLLeg_prev[i])/deltaT;
        qRLegdot[i]=(qRLeg[i]-qRLeg_prev[i])/deltaT;
      end
      for i=1,6 do
        qLLeg_prev[i]=qLLeg[i] ;
        qRLeg_prev[i]=qRLeg[i] ;
      end 
      -- qLLeg_prev=qLLeg;
      -- qRLeg_prev=qRLeg;

      qLLeg_to={};
      qRLeg_to={};
      qLLeg_to[1]=0;
      qRLeg_to[1]=0;

      for i=2,6 do 
        qLLeg_to[i] = tonumber(control_pkg[i-1+1]);
        qRLeg_to[i] = tonumber(control_pkg[5+i-1+1]) ;    
      end 

      for i=1,6 do 
        qLLeg_to[i] = (q_command[i]);
        qRLeg_to[i] = (q_command[6+i]) ;    
      end   

      for i=5,6 do 
        qLLeg_to[i] =  tonumber(control_pkg[i-1+1]);
        qRLeg_to[i] =  tonumber(control_pkg[5+i-1+1]) ;    
      end 

      ---<<<<<<<<<<<<<<<<>>>>>>>>>>>>>>>>>>>>>>>>
      --- see player/lib/NaoBody.lua -----------
      Body.set_lleg_command(qLLeg_to);
      Body.set_rleg_command(qRLeg_to);   
      -- Body.set_lleg_hardness(0.9);
      -- Body.set_rleg_hardness(0.9);

      -- Body.set_head_command(Body.get_head_position())
      Body.set_syncread_enable(1);  

      
 

      send_message="robo_msg";
        for curr_id=1,6 do
          cur_pos=  qLLeg[curr_id];  
          cur_pos=rounddeci(cur_pos,5); 
          send_message=send_message.."|"..cur_pos; 
        end
        for curr_id=1,6 do
          cur_pos=  qRLeg[curr_id];  
          cur_pos=rounddeci(cur_pos,5);
          send_message=send_message.."|"..cur_pos; 
        end
        for curr_id=1,6 do
          cur_posd=  qLLegdot[curr_id];            
          cur_posd=rounddeci(cur_posd,5);
          send_message=send_message.."|"..cur_posd; 
        end
        for curr_id=1,6 do
          cur_posd=  qRLegdot[curr_id];  
          cur_posd=rounddeci(cur_posd,5);
          send_message=send_message.."|"..cur_posd; 
        end
        
        local imuAngle = Body.get_sensor_imuAngle();
        for i=1,3 do
          send_message=send_message.."|"..rounddeci(imuAngle[i],5); 
        end

        Vg = matrix:new(Body.get_sensor_imuAcc());
        Vg = matrix.mulnum(Vg,1/matrix.normf(Vg));   
        for i=1,3 do
          send_message=send_message.."|"..rounddeci(matrix.getelement(Vg,i,1),5); 
        end           
        --angular velocities, get function gives deg/s and wrong direction for x and z    
        gyroScale = 1/3;
        Omg = matrix:new(Body.get_sensor_imuGyr());
        Omg = matrix.mulnum(Omg,gyroScale*math.pi/180);   
        matrix.setelement(Omg,1,1,-matrix.getelement(Omg,1,1))
        matrix.setelement(Omg,3,1,-matrix.getelement(Omg,3,1))
        for i=1,3 do
          send_message=send_message.."|"..rounddeci(matrix.getelement(Omg,i,1),5); 
        end             
        send_message=send_message.."|"..rounddeci(deltaT,5);
        publisher:sendx(send_message);

        if (count % 10 == 0) then
            print(unpack(q_command));
           -- os.execute("clear")
           -- local qd_lleg=Body.get_lleg_vel();
           -- print(unpack(qd_lleg))
           -- print(send_message,'\n') 
        end
  end

  local dcount = 50;

  if (count % 50 == 0) then
--    print('fps: '..(50 / (unix.time() - tUpdate)));
    
    -- update battery indicator
    Body.set_indicator_batteryLevel(Body.get_battery_level());
      local t1=unix.time();
            
  end
  
  -- check if the last update completed without errors
  lcount = lcount + 1;
  if (count ~= lcount) then
    print('count: '..count)
    print('lcount: '..lcount)
    Speak.talk('missed cycle');
    lcount = count;
  end
end



 
--Now nao are running main process separately too



t_start = Body.get_time()
t_last = Body.get_time()
t_last_update = Body.get_time()
t_frame = 0

fpscount = 0
--Now both nao and darwin runs this separately
if true then
  local tDelay = 0.0025 * 1E6; -- Loop every 2.5ms
  while 1 do
--     t=Body.get_time()
--     tPassed = t-t_last
--     t_last = t
--     if tPassed>0.005 then
-- --      print("t:",t-t_start)

--       t_frame = t_frame+ t-t_last_update
--       t_last_update=t
--       fpscount=fpscount+1
--       if fpscount%200==0 then
-- --        print("Motion FPS:",200/t_frame)
--         t_frame=0
--         fpscount=0
--         end
      update();
    -- end
    unix.usleep(tDelay);
  end
end
