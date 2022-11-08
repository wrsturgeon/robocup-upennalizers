module(..., package.seeall);
require('vector')

-- Camera Parameters

camera = {};
camera.ncamera = 2;
camera.device = {'/dev/video0', '/dev/video1'}
camera.switchFreq = 5;
camera.x_center = 320;
camera.y_center = 240;
camera.width =  {640, 320};
camera.height = {480, 240};


camera.focal_length = 545.6; -- in pixels
camera.focal_base = 640; -- image width used in focal length calculation

--New nao params

camera.param = {};
-- Contrast should be set between 17 and 64
camera.param[1] = {key='Contrast'       , val={64 , 64}};

camera.param[2] = {key='Saturation'       , val={255 , 255}};

-- Hue will automatically change to 0 if set to a number between -5 and 5, but cannot be set by other numbers
camera.param[3] = {key='Hue', val={0, 0}};

camera.param[4] = {key='Exposure'       , val={30 , 30}}; -- only enabled when autoexposure is diabled
-- Gain should be set between 32 and 255

camera.param[5] = {key='Gain'       , val={82 , 82}};

-- Sharpness should be set between 0 and 7
camera.param[6] = {key='Sharpness', val={3, 3}};

camera.param[7] = {key='Horizontal Flip', val={1, 0}};

camera.param[8] = {key='Vertical Flip', val={1, 0}};

camera.param[9] = {key='Fade to Black', val={0, 0}}; 

camera.param[10]  = {key='Do White Balance'       , val={0 , 0}};

camera.param[11] = {key='Gamma'       , val={264 , 264}} -- A value of 220 equals to 2.2 gamma.

camera.param[12] = {key='White Balance Temperature'       , val={3750 , 3750}}

camera.param[13] = {key='Power Line Frequency'       , val={2 , 2}}
-- brightness has to be set seperately from other parameters, and it can only be set to multiple of 4
--camera.brightness = 200;

camera.param[14] = {key='Auto Exposure', val={1, 1}};
--camera.param[14] = {key='Auto Exposure', val={1, 1}};
-- 0 = manual
-- 1 = auto exposure
-- 2,3 = shutter priority, etc. (have not fully tested)

camera.param[15] = {key='Auto Exposure Algorithm', val={1, 1}};
--0: Average scene brightness
--1: weighted average scene brightness
--2: evaluated average scene brightness with frontlight detection
--3: evaluated average scene brightness with backlight detection

camera.param[16] = {key='Brightness', val={16, 16}}; -- Only changeable while auto exposure is enabled!


camera.lut_file = {'Ryan_Grasp_1.raw','Ryan_Grasp_1.raw'};
