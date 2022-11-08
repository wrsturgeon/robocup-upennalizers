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
camera.param[1] = {key='Contrast'       , val={40 , 20}};

camera.param[2] = {key='Saturation'       , val={150 , 130}};
-- Hue will automatically change to 0 if set to a number between -5 and 5, but cannot be set by other numbers
camera.param[3] = {key='Hue'            , val={0 , 0}};

camera.param[4] = {key='Auto Exposure'       , val={2 , 2}};
--camera.param[4] = {key='Exposure'       , val={30 , 50}};
-- Gain should be set between 32 and 255
camera.param[5] = {key='Gain'       , val={100 , 140}};
-- Sharpness should be set between 0 and 7
camera.param[6] = {key='Sharpness'      , val={3  , 3}};

camera.param[7] = {key='Horizontal Flip', val={1  , 0}};

camera.param[8] = {key='Vertical Flip'  , val={1  , 0}};

camera.param[9] = {key='Fade to Black'  , val={0  , 0}}; 

camera.param[10]  = {key='Do White Balance'       , val={0 , 0}};

camera.param[11] = {key='Gamma'       , val={220 , 220}}

camera.param[12] = {key='White Balance Temperature'       , val={3200 , 3000}}

camera.param[13] = {key='Power Line Frequency'       , val={2 , 2}}
-- brightness has to be set seperately from other parameters, and it can only be set to multiple of 4
camera.brightness = 200;

--camera.lut_file = {'lutTOPdanpak_Japan_July262017_10AM.raw','lutBOTTOMdanpakJapan6PM.raw'};
--camera.lut_file = {'lutTOPdanpak_Japan_July262017_5PM.raw', 'lutBOTTOMdanpak_Japan_July262017_5PM.raw'};
--camera.lut_file = {'lutTOPdanpak_usopen2018_grasp_11PM.raw', 'lutBOTTOMdanpak_usopen2018_grasp_11PM.raw'};
--camera.lut_file = {'lutTOPdanpak_usopen2018_May08_5PM.raw', 'lutBOTTOMdanpak_usopen2018_May08_5PM.raw'};
camera.lut_file = {'lutTOPdanpak_usopen2018_May09_12PM.raw', 'lutBOTTOMdanpak_usopen2018_May09_12PM.raw'};
