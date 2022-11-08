require('Config');	-- For Ball and Goal Size
require('vcm');
require('unix');
require('gcm');

local Ball = require('detectBallv5');
local Goal = require('detectGoal');
local Spot = require('detectSpot');
local Line = require('detectLine');
local Circle = require('detectCircle');
local Corner = require('detectCorner');
--local Robot = require('detectRobot');
local Detection = {}
local role = gcm.get_team_role();

if(role==5) then
  Ball = require('detectBall_coach');
  print ('running detectBall_coach');
end



use_point_goal=Config.vision.use_point_goal;

enableLine = Config.vision.enable_line_detection or 0;
enableTopLine = Config.vision.enable_top_line_detection or 0;
enableSpot = Config.vision.enable_spot_detection or 0;
enableCorner = Config.vision.enable_corner_detection or 0;
enable_freespace_detection = Config.vision.enable_freespace_detection or 0;
enableBoundary = Config.vision.enable_visible_boundary or 0;
enableRobot = Config.vision.enable_robot_detection or 0;
enableCircle = Config.vision.enable_circle_detection or 0;
enableGoal = Config.vision.enable_goal_detection or 0;


print("CORNER DETECTION:",enableCorner)

--enableSpot = Config.vision.enable_spot_detection or 0;
-- For now only enable goalie to detect spot

local update = function(self, parent_vision)
  local cidx = parent_vision.camera_index;
    --top camera
  if cidx == 1 then
    if enableGoal == 1 then
    self.goal:update(Config.color.white, parent_vision);
    end
    --the bottom camera does not see the ball
    if vcm.get_ball2_detect() == 0 then
      self.ball:update(Config.color.white, self.line.ballOnLineCheck_info, parent_vision);
    end
    -- if vcm.get_line2_detect() == 0 and enableTopLine == 1 then
		if enableTopLine == 1 then
      self.line:update(Config.color.white, parent_vision);
    end
    if vcm.get_corner2_detect() == 0 and enableCorner == 1 then
      self.corner:update(Config.color.white, parent_vision, self.line);
    end
		if vcm.get_circle2_detect() == 0 and enableCircle == 1 then
			self.circle:update(parent_vision, self.line);
		end
    if vcm.get_spot2_detect() == 0 and enableSpot == 1 then
      self.spot:update(Config.color.white, parent_vision);
    end
  end
  --bottom camera
  if cidx == 2 then
    if enableLine == 1 then
      self.line:update(Config.color.white, parent_vision);
    end

    self.ball:update(Config.color.white, self.line.ballOnLineCheck_info, parent_vision);

    if enableCircle == 1 then
	    self.circle:update(parent_vision,self.line);
    end
    if enableSpot == 1 then
      self.spot:update(Config.color.white, parent_vision);
    end

    if enableCorner == 1 then
      self.corner:update(Config.color.white, parent_vision, self.line);
    end
  end
end


local update_shm = function(self, parent_vision)
  indx = parent_vision.camera_index;
  if indx == 1 then
    if enableGoal == 1 then
      self.goal:update_shm(parent_vision);
    end
    --if vcm.get_line2_detect() == 0 and enableTopLine == 1 then
		if enableTopLine == 1 then
      self.line:update_shm(parent_vision);
    end
    if vcm.get_ball2_detect() == 0 then
      self.ball:update_shm(parent_vision);
    else
    	vcm.set_ball1_detect(0);
    end
    if vcm.get_corner2_detect() == 0 and enableCorner == 1 then
      self.corner:update_shm(parent_vision);
    end
		if vcm.get_circle2_detect() == 0 and enableCircle == 1 then
			self.circle:update_shm(parent_vision);
		end

    if (vcm.get_spot2_detect() == 0 and enableSpot == 1) then
      self.spot:update_shm(parent_vision);
    end

  end
  if indx == 2 then

    self.ball:update_shm(parent_vision);

    if enableSpot == 1 then
      self.spot:update_shm(parent_vision);
    end
    if enableLine == 1 then
      self.line:update_shm(parent_vision);
    end
    if enableCircle == 1 then
	    self.circle:update_shm(parent_vision);
    end
    if enableCorner == 1 then
      self.corner:update_shm(parent_vision);
    end


  end
end


function Detection.exit()
end

function Detection.entry(parent_vision)
  -- Initiate Detection
  local self = {}
  -- add method
  self.update = update
  self.update_shm = update_shm
  self.ball = Ball.entry(parent_vision)
  if enableLine == 1 then self.line = Line.entry(parent_vision) end
  local indx = parent_vision.camera_index;
  if indx == 1 and enableGoal == 1 then
    self.goal = Goal.entry(parent_vision)
  end
  if enableSpot ==1 then self.spot = Spot.entry(parent_vision) end
  if enableCorner ==1 then self.corner = Corner.entry(parent_vision) end
  if enableCircle ==1 then self.circle = Circle.entry(parent_vision) end

  --vcm.set_corner_detect(0) -- hack to avoid localzation BUG!

  return self
end

return Detection
