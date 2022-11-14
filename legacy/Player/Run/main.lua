-- THE START OF THE MAIN PROGRAM LOOP
-- update() called every "0.005" (seconds?) from ./legacy/Player/run_main.lua, and that's literally all run_main does
-- control flow (TL;DR: basically *just* updating FSMs individually):
--   - Motion.entry()
--       - robot walks onto the field...?
--   - update() [from ./legacy/Player/run_main.lua]
--       - some probably broken battery-level shit
--       - ...opening a broadcast socket every loop iteration?
--       - checking, at runtime, whether or not this is the first iteration of the loop
--           - configuring if not
--           - else, update FSMs individually
--       - get the body's battery level for the third time
-- Best bet for tracing further control flow:
--   - ./legacy/Player/BodyFSM/[here it gets murky]BodyFSM.lua(?):update()
--   - ./legacy/Player/GameFSM/GameFSM.lua(?):update()
--   - ./legacy/Player/HeadFSM/HeadFSM.lua(?):update()

cwd = cwd or os.getenv('PWD')
package.path = cwd.."/?.lua;"..package.path;
require('init') -- Player/init.lua

--cwd = os.getenv('PWD')
--require('init')

require('unix')
require('Config')
require('shm')
require('vector') -- Player/Util/vector.lua
require('vcm') -- Player/Vision/vcm.lua
require('gcm') -- Player/World/gcm.lua
require('wcm') -- Player/World/wcm.lua
require('mcm') -- Player/Motion/mcm.lua
require('Speak') -- Player/Util/Speak.lua
require('getch')
require('Body') -- Lib/Platform/{NaoV4/WebotsNao}/Body/Nao{Webots}Body.lua
require('Motion') -- Player/Motion/Motion.lua

gcm.say_id();

Motion.entry();

darwin = false;
webots = false;

wcm.set_process_broadcast(0) --Force turn off broadcast; turning this on can lead to arb crashing (trying to do actions on a "role" which has a nil value)

init = false;
calibrating = false;
ready = false;

smindex = 0;
initToggle = true;

-- main loop
count = 0;
lcount = 0;
tUpdate = unix.time();
BatteryLevel = 0


function update()
--[[
 --- play song if Config.playSong == true
  if gcm.get_game_state() == 1 then
        if Config.playSong then
                os.execute("/usr/local/bin/screen -dm -L -s /bin/bash -S music aplay " .. Config.songName) --./Music/band-march.wav")
                Config.playSong = false
        end
  elseif gcm.get_game_state() ~= 1 then
        os.execute("/usr/local/bin/screen -S music -X quit")
  end
--]]



        --speak battery level
        local batteryL = Body.get_battery_level();
    --    print("Battery = " .. batteryL)
        if batteryL ~= batteryLevel and batteryL < 6 then
                Speak.talk("Battery Level   " .. batteryL)
                batteryLevel = Body.get_battery_level()
        end 



  count = count + 1;
  --Update battery info
  wcm.set_robot_battery_level(Body.get_battery_level());
  vcm.set_camera_teambroadcast(1); --Turn on wireless team broadcast

  if (not init)  then
    if (calibrating) then
      if (Body.calibrate(count)) then
        Speak.talk('Calibration done');
        calibrating = false;
        ready = true;
      end
    elseif (ready) then
      -- initialize state machines
      package.path = cwd..'/BodyFSM/'..Config.fsm.body[smindex+1]..'/?.lua;'..package.path;
      package.path = cwd..'/HeadFSM/'..Config.fsm.head[smindex+1]..'/?.lua;'..package.path;
      package.path = cwd..'/GameFSM/'..Config.fsm.game..'/?.lua;'..package.path;
      require('BodyFSM')
      require('HeadFSM')
      require('GameFSM')

      BodyFSM.entry();
      HeadFSM.entry();
      GameFSM.entry();

      init = true;
    else
      if (count % 20 == 0) then
        Speak.talk('Calibrating');
        calibrating = true;
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
    GameFSM.update();
    BodyFSM.update();
    HeadFSM.update();
    Motion.update();
    Body.update();
  end

  local dcount = 50;
  if (count % 50 == 0) then
--    print('fps: '..(50 / (unix.time() - tUpdate)));
    tUpdate = unix.time();

    -- update battery indicator
    Body.set_indicator_batteryLevel(Body.get_battery_level());
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
