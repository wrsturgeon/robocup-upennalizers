--http://zguide.zeromq.org/lua:client
require "zhelpers"
local zmq      = require "lzmq"
local zthreads = require "lzmq.threads"
local ztimer   = require "lzmq.timer"
local zpoller  = require "lzmq.poller"


local context = zmq.init(1)

--  Socket to talk to server
print("Connecting to hello world server...")
local socket = context:socket(zmq.REQ)
socket:connect("tcp://localhost:5555")

for n=1,10 do
    print("Sending Hello " .. n .. " ...")
    socket:send("Hello")

    local reply = socket:recv()
    print("Received World " ..  n .. " [" .. reply .. "]")
end
socket:close()
context:term()

