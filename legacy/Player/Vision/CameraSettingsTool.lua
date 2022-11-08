ImageProc = require('ImageProc');
require('vcm');

 -- Any number x>0 means that upon wakeup, the autoexposure will activate for x itterations
 -- WARNING! if x>0 do robot must be looking at field during startup!!! It will correct eventually but slowly
local camera_top_tick = 12
local camera_bottom_tick = 12

-- Allowable error before autoexposure activates 
-- Error is measured in brightness units from goal (you need to play with it)
camera_top_start_error = 40
camera_bottom_start_error = 9999

-- Allowable error before autoexposure deactivates
-- Error is measured in brightness units from goal (you need to play with it)
camera_top_stop_error = 5
camera_bottom_stop_error = 5

-- number of exposure ticks when error is above allowable error
camera_top_exposure_length = 2
camera_bottom_exposure_length = 2 

camera_top_goal = 170 -- goal of top camera (mean of maximums of Y channel in ycbcr)
camera_bottom_goal = 60 -- goal of top camera (mean of maximums of Y channel in ycbcr)

 -- Not a config param (static variable)
local camera_gain_top = 0.0
local camera_gain_bottom = 0.0

local update = function(self, parent_vision)

	-- [[ multiline comment

	-- Ryan's 2019 attempt at a good autoexposure
	-- The autoexposue in the camera drivers is not sufficient
	-- The camera's drivers apply gain only

	-- Saturation: how colorful vs how gray the image is
	-- Gain: The analog multiplier to a collected pixel value before being digitized
	-- Exposure: How long the apature collects light (cummulative add to pixel value)

	-- Increasing exposure increases image brightness and saturation
	-- Increasing Gain increases brightness only but will lead to  washed out images for low light images

	-- The idea is that all three of these need to be changed at once
	-- A better method than mine would be to keep saturation in a different control loop, probably by looking at HSL or HSV color spaces
  
	cidx = parent_vision.camera_index
	yuyvImg = vcm['get_image'..cidx..'_yuyv']();
  
	if cidx == 1 then -- Top camera

		y_raw  = ImageProc.yuyv_to_ycbcr(yuyvImg, 1)

		n_rows_pct = .4 -- percentage of image of which to take lower rows from to use for calculation (idea: dumb non-genometric way to remove non field area)
		n_rows = math.floor(y_raw:size(1)*n_rows_pct)
		row_subset = torch.range(1, n_rows):add(1-n_rows_pct)
		area_subset = y_raw[{row_subset, {}}]

		y_sensor = ( torch.max(area_subset, 1):float():mean() + torch.max(area_subset, 2):float():mean() ) / 2
		camera_error = y_sensor-camera_top_goal

		-- We don't want to update th autoexposure all the time since doing so yeilds a .75s delay (this throws off localization)
		-- Keep a tick variable to record how many frames we want the robot to recalibrate the exposure
		if math.abs(camera_error) >= camera_top_start_error then
			camera_top_tick = camera_top_exposure_length
		elseif camera_top_tick > 0 then
			camera_top_tick = camera_top_tick - 1
		end

		--print('Top gain \t\t\t', camera_error)

		-- Do autoexposure
		if camera_top_tick > 0 and math.abs(camera_error) >= camera_top_stop_error then

			camera_gain_top = camera_gain_top - camera_error*0.015 -- linear control

			exposure = 30 + camera_gain_top*7.5
			gain = 82 + camera_gain_top*10
			--saturation = math.max(255 - camera_gain_top*1.5, 255)

			parent_vision.camera:set_param('Exposure', exposure, 0);
			parent_vision.camera:set_param('Gain', gain, 0);
			--self.camera:set_param('Saturation', saturation, 0);
			
		end
		
		--print('CamTop:', camera_error)
		


	-- Bottom Camera does not need as much attention

	else -- Bottom camera

		y_sensor = ImageProc.yuyv_to_ycbcr(yuyvImg, 1):float():mean()
		camera_error = y_sensor-camera_bottom_goal

		--print('Bottom gain \t\t\t', camera_error)

		-- We don't want to update the autoexposure all the time since doing so yeilds a .75s delay (this throws off localization badly)
		-- Keep a tick variable to record how many frames we want the robot to recalibrate the exposure
		if math.abs(camera_error) >= camera_bottom_start_error then
			camera_bottom_tick = camera_top_bottom_length
		elseif camera_bottom_tick > 0 then
			camera_bottom_tick = camera_bottom_tick - 1
		end

		-- Do autoexposure
		if camera_bottom_tick > 0 and math.abs(camera_error) >= camera_bottom_stop_error then

			camera_gain_bottom = camera_gain_bottom - camera_error*0.015  -- linear control

			exposure = 30 + camera_gain_bottom*7.5
			gain = 82 + camera_gain_bottom*10
			--saturation = math.max(255 - camera_gain_bottom*1.5, 255)

			parent_vision.camera:set_param('Exposure', exposure, 1);
			parent_vision.camera:set_param('Gain', gain, 1);
			--self.camera:set_param('Saturation', saturation, 1);

		end
		
		--print('CamBottom:', camera_error)
					
	end
  
end

local CameraSettingsTool = {}

function CameraSettingsTool.entry(parent_vision)
	print('init CameraSettingsTool')

	-- Initiate Detection
	local self = {}
	--local cidx = parent_vision.camera_index;

	-- add method
	self.update = update
	return self
end

return CameraSettingsTool
