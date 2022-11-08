-- Pubsub envelope subscriber
--https://github.com/booksbyus/zguide/blob/master/examples/Lua/psenvsub.lua
require "zhelpers"
local zmq = require "lzmq"

-- Prepare our context and publisher
local context = zmq.context()
local subscriber, err = context:socket{zmq.SUB,
  subscribe = "robo_msg";
  connect   = "tcp://192.168.123.103:5562";
}
zassert(subscriber, err)

while true do
  -- Read envelope with address and message contents
  local address_contents = subscriber:recvx()
  printf ("[%s]\n", address_contents); 
end

--  We never get here but clean up anyhow
subscriber:close()
context:term()
