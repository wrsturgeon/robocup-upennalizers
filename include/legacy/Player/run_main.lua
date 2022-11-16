-- THE START OF EVERYTHING
-- This is the first file (other than maybe detect_whistle) that's called from ./game main
-- Control flow:
--   - disgusting loop that blocks until "0.005" (presumably seconds?) have passed
--   - calls "update()" (fuck Lua's import system--can't tell where this comes from)
--       - tracked it down with `grep -rnw`: ./legacy/Player/Run/main.lua:114

cwd = os.getenv('PWD')
require('init') -- Player/init.lua

require('unix');
require('main'); -- Player/Run/main.lua (probably?)
require('Body') -- Player/Dev/Body.lua

local t_last = Body.get_time()
while 1 do 
  local t=Body.get_time() 
  tPassed = t-t_last
  t_last = t
  if tPassed>0.005 then
    update()
  end 
  tDelay = 0.005*1E6;	
  unix.usleep(tDelay);
end
