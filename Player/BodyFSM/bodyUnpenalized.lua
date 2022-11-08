module(..., package.seeall);
require('Body')
require('Motion')
require('wcm')
require('velgeneration')

t0 = 0;
timeout1 = 5;
timeout2 = 20.0;

local log = require 'log';
if Config.log.enableLogFiles then
    log.outfile = (Config.log.behaviorFile);
end
log.level = Config.log.logLevel;

--When unpenalized, the robot usually cannot find the ball instantly 
--And start spinning around
--This state makes the robot enter the field and THEN start spinning

function entry()
  print(_NAME..' entry');
  t0 = Body.get_time();
end

function update()
  t = Body.get_time();
  
  --walk to somewhere near center of our half
  goalDef = wcm.get_goal_defend();
  walkTo = {};
  walkTo[1] = goalDef[1]/2;
  walkTo[2] = 0;
  walkTo[3] = 0;
  
  vx,vy,va = velgeneration.getRoleSpecificVelocity(walkTo);
  walk.set_velocity(vx,vy,va);
  log.warn(vx .. vy .. va .. "7");

  ball = wcm.get_ball();
  if (t-ball.t<0.2) and (t-t0 > timeout1) then return "done" end
  if (t-t0>timeout2) then return "done" end
end

function exit()
end
