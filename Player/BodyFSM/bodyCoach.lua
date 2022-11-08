module(..., package.seeall);
require('Motion')

function entry()
  print(_NAME..' entry');
  Motion.event("sit");
end

function update()
  
end

function exit()
  
end
