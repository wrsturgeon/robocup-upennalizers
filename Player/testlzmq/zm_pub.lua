-- Pubsub envelope publisher
--https://github.com/booksbyus/zguide/blob/master/examples/Lua/psenvpub.lua
require "zhelpers"
local zmq = require "lzmq"

-- Prepare our context and publisher
local context = zmq.context()
local publisher, err = context:socket{zmq.PUB, bind = "tcp://*:5562"}
zassert(publisher, err)

while true do
  -- Write two messages, each with an envelope and content 
  publisher:sendx("robo_msg 1|2|3|5")
  sleep (0.1);
end

--  We never get here but clean up anyhow
publisher:close()
context:term()