Changes in codebase from Japan2017 branch for Webots 2019a. Done by Abdullah Zaini

comment out #field SFFloat gpsResolution 0.0 (not neccesary, use the nao.proto instead).
So basically swap the Nao_H21_V40GPSOnly.proto with Nao.proto

test_main_webots_parallel
--change robot_keyboard to keyboard. Line 47 and 64

include motor.h and keyboard.h in the lua_controller.i file
replace lua_controller.i reference to servo and replace its usage in NaoWebotsBody to motor commands.

Add the compass into the Nao.proto.

lowercase gps instead of capitalized gps

ALSO YOU NEED TO CREATE A LINK TO THE CONTROLLERS. 

follow this for nao_team_0
https://gist.github.com/quinnwu/725136667d6b36a6fc3d


copy ballGPS into controllers/ballGPS to get the ballGPS that we're using


------------------------------------------------------------------------------
--------------------Setting Up Webots on a New Computer-----------------------
------------------------------------------------------------------------------
By Abdullah Zaini (based on quinnwu's documentation)

step 0:

run the following commands to move your webotsHome to /usr/local/
Mac:
cd /Applications/
ln -s /Webots /usr/local/
Linux:
sudo ln -s ~/PATH_TO_WEBOTS/webots /usr/local/webots
For example mine was: sudo ln -s ~/webots /usr/local/webots

step 1: 

(create symbolic link. Basically just link WebotsController/ to WebotsProject/controllers and call it nao_team_0)

Run: ln -s ~/PATH_TO_UPENNDEV/upenndev/WebotsController/ ~/PATH_TO_UPENNDEV/upenndev/WebotsProj/controllers/nao_team_0

Mine was: ln -s ~/Documents/upenndev/WebotsController/ ~/Documents/upenndev/WebotsProj/controllers/nao_team_0

step 2: (install luajit)
sudo apt-get install luajit

step 3: (ballGPS controller)
then go to the google drive and download the file in behavior/webots call ballGPS and put it in you ballGPS folder (which is in WebotsProject/controllers/ballGPS). You'll need to right click on the ballGPS exectuable (what you just got off the google drive) and give it permission to run as an executable (should be a tick box)
