module(..., package.seeall);

require('Body')
require('walk')
require('gcm')
require('vcm')
require('wcm')
require('Speak')
require('util')

t0 = 0;
tLastCount = 0;

tKickOff = 12.0; --How long should we wait till gamePlay?
ballClose = 0.50; --If the ball comes any closer than this, start moving

-- if Config.fsm.playMode == 1 then wait_kickoff = 0 --No kickoff wait for demo
-- else wait_kickoff = Config.fsm.wait_kickoff or 0 end
local wait_kickoff = (Config.fsm.playMode ~= 1 and Config.fsm.wait_kickoff == 1)

function entry()
  print(_NAME..' entry')
  walk.stop()
end

function update()
  print("bodyStart update")

  role = gcm.get_team_role();
  if role == 0 then 
    return 'goalie'
  end

  if Config.game.role == 5 then
    --COACH
    return 'coach'
  end

  return 'player'
end


function exit()
end
