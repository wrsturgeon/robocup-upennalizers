module(..., package.seeall);

require('Body')
require('walk')
require('vector')
require('Config')
require('wcm')
require('mcm')
require('velgeneration')

local log = require 'log';
if Config.log.enableLogFiles then
    log.outfile = (Config.log.behaviorFile);
end
log.level = Config.log.logLevel;

t0 = 0;
direction = 1;

vSpin = Config.fsm.bodySearch.vSpin or 0.3;
turnAngleLimit = Config.fsm.bodySearch.turnAngleLimit or math.pi / 2;
thClose = Config.fsm.bodyGoaliePosition.thClose;

function entry()
  log.info(_NAME.." entry");

  t0 = Body.get_time();

  -- set turn direction to last known ball position
  ball = wcm.get_ball();
  if (ball.y > 0) then
    direction = 1;
    mcm.set_walk_isSearching(1);
  else
    direction = -1;
    mcm.set_walk_isSearching(-1);
  end


  role = gcm.get_team_role();
  --Force attacker for demo code
  if Config.fsm.playMode == 1 then role = 1; end
  if role == 0 then
    timeout = Config.fsm.bodySearch.timeout or 3.5*Config.speedFactor;
  else
    timeout = Config.fsm.bodySearch.timeout or 10.0*Config.speedFactor;
  end
end

function update()
  local t = Body.get_time();
  ball = wcm.get_ball();
  pose = wcm.get_pose();

  -- search/spin until the ball is found
  vx, vy, va = velgeneration.bodySearchVelocity(vSpin, direction)
  walk.set_velocity(vx, vy, va);
  if Config.fsm.velocity_testing then  
     log.warn(vx, " ", vy, " ", va, " 3");
  end

  if (t - ball.t < 0.5) then
    if role == 0 then
      log.debug("Transition: ballgoalie");
      return "ballgoalie";
    else
      log.debug("Transition: ball");
      return "ball";
    end
  end
  if (t - t0 > timeout) then
    if role == 0 then
      log.debug("Transition: timeoutgoalie");
      return "timeoutgoalie"
    else
      log.debug("Transition: timeout");
      return "timeout";
    end
  end
end

function exit()
  mcm.set_walk_isSearching(0);
end
