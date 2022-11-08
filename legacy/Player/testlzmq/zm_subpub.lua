require "zhelpers"
local zmq = require "lzmq"


local context = zmq.context()
local subscriber, err = context:socket{zmq.SUB,
  subscribe = "robo_msg";
  connect   = "tcp://localhost:5561";
}
zassert(subscriber, err)

local context = zmq.context()
local publisher, err = context:socket{zmq.PUB, bind = "tcp://*:5562"}
zassert(publisher, err)


while true do
  -- Read envelope with address and message contents
  local address_contents = subscriber:recvx()
  printf ("[%s]\n", address_contents); 
  publisher:sendx("robo_states" .. 1 .. "|" .. 3 .. "|" .. 12 .. "|")
end

--  We never get here but clean up anyhow
subscriber:close()
context:term()