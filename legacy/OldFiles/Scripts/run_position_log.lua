require('position_log');
require('unix');
require('os');

while true do
  os.execute("clear");
  tDelay = 0.35;
  position_log.update();
  unix.sleep(tDelay);
end
