module(..., package.seeall);
require('Motion')
require'gcm'

function entry()
  gcm.set_game_bodystate(1)
  print(_NAME..' entry');
  Motion.event("sit");
end

function update()
  Motion.event("sit");
end

function exit()
  Motion.sm:set_state('stance');
end
