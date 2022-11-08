--https://github.com/booksbyus/zguide/blob/master/examples/Lua/psenvsub.lua
require "zhelpers"
local zmq      = require "lzmq"
local zthreads = require "lzmq.threads"
local ztimer   = require "lzmq.timer"
local zpoller  = require "lzmq.poller"

local context = zmq.init(1)

--  Socket to talk to clients
local socket = context:socket(zmq.REP)
socket:bind("tcp://*:5555")

while true do
    --  Wait for next request from client
    local request = socket:recv() 
    print("Received Hello [" .. request .. "]")

    --  Do some 'work'
        s_sleep(100)

    --  Send reply back to client
    socket:send("World")
end
--  We never get here but if we did, this would be how we end
socket:close()
context:term()