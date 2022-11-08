module(..., package.seeall);
require('Body')
require('walk')
require('util')
require('vector')
require('Config')
require('wcm')
require('gcm')

require('targetpose')
require('velgeneration')

t0 = 0;

rClose = Config.fsm.bodyReady.thClose[1];
thClose = Config.fsm.bodyReady.thClose[2];

-- don't start moving right away
tstart = Config.fsm.bodyReady.tStart or 5.0;
phase=0; --0 for wait, 1 for approach, 2 for turn, 3 for end
side_y = 0;

local log = require 'log';
if Config.log.enableLogFiles then
    log.outfile = (Config.log.behaviorFile);
end
log.level = Config.log.logLevel;

function entry()
  print(_NAME.." entry");
  phase=0;
  Motion.event('standup')
  walk.set_velocity(0,0,0)
  if Config.fsm.velocity_testing then
     log.warn("0 ", "0 ", "0 ", "8");
  end
  t0 = Body.get_time();

end

function update()
  local t = Body.get_time();
  local pose = wcm.get_pose()  
  local homepose = targetpose.getReadyHomePose()
  gcm.set_game_walkingto({homepose[1],homepose[2]})
  -- goalie does not walk in normal game.
  -- it walks in dropin game

  role = gcm.get_team_role()
  if role == 0 and Config.dev.team ~= 'TeamDropin' then
    walk.stop()
    return
  else
    if walk.active==false and phase==0 then walk.start() end
  end

  local vx,vy,va, rHome,aHome = velgeneration.getReadyVelocity(homepose,phase)
  walk.set_velocity(vx, vy, va);

  if phase==0 and t - t0 > tstart then phase =1; return end
  if phase==1 and rHome < rClose then phase=2; end
  if (rHome < rClose and math.abs(aHome)<thClose) or phase==3 then 
    walk.stop(); 
    phase=3;
  end  
end

function exit()
end

