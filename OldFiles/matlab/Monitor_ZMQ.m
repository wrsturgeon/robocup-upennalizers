function Monitor_ZMQ(teamID, playerID)
%-----------------------------------------------------
%
%  Usage: Monitor(1,2)       : single monitor
%
%-----------------------------------------------------
close all;

% Init
t0 = tic;

% init team and player
if nargin < 2
  
  team_number = 1;
  player_id = 1;
else
  team_number = teamID;
  player_id = playerID;
end

lua_ins = lua;
% load config from Config.lua
[platform, ncamera] = lua_ins.load_config();

%% init monitor
Monitor = event_monitor(ncamera);
%%Mon = show_monitor_simple(ncamera);

% init zmq to listen
robot = zmq_robot(team_number, player_id,...
                  ncamera, Monitor);

t = toc( t0 );
fprintf('Initialization time: %f\n',t);

while 1
  robot.update();
%  Mon.update(robot_zmq);
  drawnow;
end
