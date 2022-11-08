module(..., package.seeall);
local unix = require('unix')
require('vector')
require('util')
--require('parse_hostname')


--Robot CFG should be loafsmd first to set PID values
local robotName = unix.gethostname();

--Speak enable
speakenable = 0;

-- play song
playSong = false
--songName = "./Music/band-march.wav"
songName = "./Music/cheers.wav"

platform = {};
platform.name = 'NaoV4'

listen_monitor=1

-- Game Parameters
-- init game table first since fsm need it
game = {};

-- Parameters Files
params = {}
params.name = {"Walk", "World", "Kick", "Vision", "FSM", "Camera","Robot"};
-- Select walk Confif file {from Player/Config folder}

params.Walk = "2018"



----------    Select world file    -------------------
local worldFiles = {
	"SPL17Grasp",
	"SPL17",
  	"SPL17Mixed",
	"SPL19_newGrasp"
}
params.World = worldFiles[4]
--------Setting Player ID's----------
--we define all names here for team monitor (now we are not sending robot names)
--Now ids should not overlap
robot_names_ids={
  tink=3,
  ticktock=2,
  hook=6,
  pockets=4,
  dickens=5,
  wendy=1
}

-- Assign team number(To receive commands from game controller)
game.teamNumber = 22 --22. for testing new game controller;
game.robotName = robotName
game.playerID = robot_names_ids[robotName] or 0
game.robotID = game.playerID
game.teamColor = 0 --{ 0 is blue team, 1 is red team} -- parse_hostname.get_team_color()
game.nPlayers = 6
game.whistle_pitch = 100
game.whistle_mag = 10000

if game.playerID == 6 then
    game.role = 3;
elseif game.playerID == 7 then
    game.role = 5;
else
    game.role = game.playerID - 1; -- 0 for goalie
end

--- Location Specific Camera Parameters --
cameraFiles= {
		"Wang_Grasp_May202016_3pm",
		"Wang_GRASP_June232016_11am",
                "danpak_April232017_3PM",
                "Japan07242017_10AM",
		"JapanJuly242017_12PM_adjustedExposure",
		"Japan_July252017_10PM",
                "danpak_usopen2018_grasp_11PM",
    "danpak_autoexposure",
    "Ryan_Grasp_Jun2019_Constant",
    "Ryan_Grasp_Jun2019_Autoexposure"
}
params.Camera = cameraFiles[10];

local robotBodyName_override = nil --nil or robot body name, if robot body is different from head
local robot_body
if robotBodyName_override then
  --robot_body = robotBodyName_override
else
  --robot_body = robotName
end
robot_body = nil

--calibrated values from Matlab GUI tool
--ht.calib_val = {bodyHeight, bodyTilt, neckZ, focalA_top, focalA_bottom}
if robot_body == "pockets" then
  ht_calib_vals = {0.32435, 0.014695, 0.14403, 276.3449, 146.8324}
elseif robot_body == "tink" then
  ht_calib_vals = nil
elseif robot_body == "wendy" then
  ht_calib_vals = {0.31486, 0.022287, 0.13449, 272.842, 133.8039}
elseif robot_body == "dickens" then
  ht_calib_vals = {0.31674, 0.081817, 0.13768, 283.7728, 131.854}
elseif robot_body == "hook" then
  ht_calib_vals = {0.31465, -0.017199, 0.13533, 277.239, 136.3956}
elseif robot_body == "ticktock" then
  ht_calib_vals = {0.29591, -0.061934, 0.11979, 273.3067, 130.047}
else
  print("invalid robot_body name, using default headTransform config")
  ht_calib_vals = nil
end



--if (robotName == "bacon" or robotName == "tink") then params.Camera = cameraFiles[5] end
--if (game.role == 5) then
--        params.Camera = cameraFiles[4]
--end
 util.LoadConfig(params, platform)
------------------------------------------

-- Devive Interface Libraries
dev = {};
dev.comm = 'TeamComm' -- {This is .so file in Lib} --New one with STD comm moduled
dev.body = 'NaoBodyII'; -- {This file is in Player/Lib}
dev.camera = 'uvc'; -- {This is .so file in Lib}
dev.kinematics = 'NaoKinematics'; -- {This is .so file in Lib}
dev.ip_wired = '192.168.123.255';
dev.ip_wired_port = 111111;
dev.ip_wireless = '192.168.1.255'; -- PENN WIFI (2018)
--dev.ip_wireless = '10.0.255.255'; -- ROBOCUP WIFI (CANADA 2018)
dev.ip_wireless_port = 10022
dev.ip_wireless_gc = '192.168.1.130';
--dev.ip_wireless_gc = '10.0.254.2';
--dev.ip_wireless_gc = '10.0.0.2';
dev.ip_wireless_coach = '192.168.1.255';
dev.game_control = 'NaoGameControl';
dev.team = 'TeamSPL'; -- {This file is in Player/World}


-- FSM Parameters
fsm.game = ''; -- select GameFSM
fsm.body = {''}; -- select BodyFSM
fsm.head = {''}; -- select HeadFSM

-- Team Parameters
team = {};
team.msgTimeout = 5.0;
team.tKickOffWear = 7.0;

team.walkSpeed = 0.1; --average walking speed for eta calc m/s
team.turnSpeed = 2.0; --Average turning speed rad/s
team.ballLostPenalty = 4.0; --ETA penalty per ball loss time
team.fallDownPenalty = 10.0; --ETA penalty per ball loss time
team.standStillPenalty = 3.0; --ETA penalty per emergency stop time
team.nonAttackerPenalty = 0.2; -- distance penalty from ball
team.nonDefenderPenalty = 0.5; -- distance penalty from goal
team.force_defender = 0;--Enable this to force defender mode
team.test_teamplay = 0; --Enable this to immobilize attacker to test team beha$

-- if ball is away than this from our goal, go support ------
team.support_dist = 3.0;
team.supportPenalty = 0.5; --dist from goal
team.use_team_ball = 0;
team.team_ball_timeout = 3.0;  --use team ball info after this delay
team.team_ball_threshold = 0.5;

team.avoid_own_team = 0;
team.avoid_other_team = 0;

team.yFieldOffset = 3;

team.rCloseDefender = 0.6;
team.maxTurnError = 135*math.pi/180;
team.closeAngle = 20*math.pi/180;

--defender pos: (dist from goal, side offset)
team.defender_pos_0 = {1.0, 0}; --In case we don't have a goalie
team.defender_pos_1 = {2, 0.3}; --In case we have only one defender
team.defender_pos_2 = {2, 0.4}; --two defenders, left one
team.defender_pos_3 = {2, -0.4}; --two defenders, right one

team.defenderRangeX = 4.0;


team.supporter_pos = {0.75, 1.25};

team.maxSupporterX = 4.0;

team.use_team_ball = 0;
team.team_ball_timeout = 3.0;  --use team ball info after this delay
team.team_ball_threshold = 0.5;

team.flip_correction = 0;



-- keyframe files
km = {};
if robotName ~= "ruffio" then
	km.standup_front = 'bh_getupFromFrontslow.lua';
	km.standup_front2= 'bh_getupFromFrontslow.lua';
	km.standup_back = 'bh_getupFromBack.lua';
	km.standup_back2 = 'bh_getupFromBack.lua';
else
	km.standup_front = 'km_NaoV4_StandupFromFrontBH.lua';
	km.standup_front2= 'km_NaoV4_StandupFromFrontBH.lua';
	km.standup_back = 'km_NaoV4_StandupFromBackBH.lua';
	km.standup_back2 = 'km_NaoV4_StandupFromBackBH.lua';
end

--if robotName == "pockets" then
--	km.standup_back='km_NaoV4_StandupFromBack_Fast.lua'; --commented out to test getups for germany 2016
--end

km.time_to_stand = 30; -- average time it takes to stand up in seconds

--vision.ball.max_distance = 2.5; --temporary fix for GRASP lab
vision.ball.fieldsize_factor = 1.2; --check whether the ball is inside the field
vision.ball.max_distance = 2; --if ball is this close, just pass the test

--Should we use ultrasound?
team.avoid_ultrasound = 1;

use_kalman_velocity = 0;

team.flip_threshold_x = 3;
team.flip_threshold_y =2.5;


team.vision_send_interval = 30


walk.variable_step = 1--disable this if you don't have invhyp.so
fsm.goalie_type = 2 --Moving and stopping goalie
fsm.goalie_reposition = 2 --Position reposition
fsm.goalie_use_walkkick = 1
team.flip_correction = 1

--Logging
log = {};
log.enableLogFiles = false; --enables writing to file
log.overwriteFiles = true; --overwrites the files every time (clears entire Logs/ folder)
log.logLevel = 'debug'; --order is: trace,debug,info,warn,error,fatal
log.behaviorFile = 'Logs/behavior.txt';
log.teamFile = 'Logs/team.txt';
log.worldFile = 'Logs/world.txt';
log.motionFile = 'Logs/motion.txt';
log.visionFile = 'Logs/vision.txt';


--[[
fsm.bodyApproach.yTarget21 = {0.025,0.04,0.055}
--]]

--ENABLE THIS BLOCK FOR THE NEW KICK
--[[
largestep_enable = true
dev.walk = 'DirtyAwesomeWalk'
--OG value: {0.18 0.20} / {0.03 0.045 0.06}
fsm.bodyApproach.xTarget21 = {0,0.21,0.23} --little away
--]]

fsm.new_head_fsm = 1
fsm.velocity_testing = false;
fsm.mixedGame = false;
roll_feedback_enable = 1
pitch_feedback_enable = 1

odom_testing = false;

enable_getup = true;
disable_walk = false

disable_gyro_feedback = false

--Change values here for dropin
--Make sure to change player number too!
dropinGame = false
if dropinGame then
    game.teamNumber = 99;
    dev.ip_wireless_port = 10099;
    dev.team = 'TeamDropin';
    team.force_attacker = 1;
end

--mixedGame = true
if fsm.mixedGame then
  --No 2 as supporter, 3 as defender, 6 as defender 2
    if game.playerID == 2 then
       game.role = 3;
    elseif game.playerID == 3 then
       game.role = 2;
    else
       game.role = 4;
    end
    game.teamNumber = 93;
    dev.ip_wireless_port = 10093; --might be 10145
    dev.team = 'TeamMixed';
    team.force_attacker = 0;
    robot_ids_penn = {2,3,6};  -- change this before mixed team games!
end
