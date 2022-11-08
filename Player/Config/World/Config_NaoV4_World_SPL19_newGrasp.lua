module(..., package.seeall);
require('vector')
local unix = require('unix');

local robotName = unix.gethostname();
--Localization parameters for testing in multiRobots lab in new Grasp
--The field is 50-60% of its real size
--But the size of the boxes and the distance between the goal posts are unchanged

world={};
world.n = 200;
world.xLineBoundary = 3.69;
world.yLineBoundary = 1.655;
world.xMax = 3.9;
world.yMax = 1.7;
world.goalWidth = 1.70;
world.goalHeight= 0.85;
world.goalDiameter=0.10; -- diameter of a post
world.ballYellow= {{4.5,0.0}};
world.ballCyan= {{-4.6,0.0}};
world.postYellow = {};
world.postYellow[1] = {3.69, 0.85};
world.postYellow[2] = {3.69, -0.85};
world.postCyan = {};
world.postCyan[1] = {-3.69, -0.85};
world.postCyan[2] = {-3.69, 0.85};
world.spot = {};
world.spot[1] = {-2.35, 0};
world.spot[2] = {2.35, 0};
world.cResample = 10; --Resampling interval
world.circle = {};
world.circle[1] = {0,0};
world.circle[2] = {0,0};

--0.46 x  1.08 y

--These are GRASP field values
world.Lcorner={};
--Field edge
world.Lcorner[1]={3.69,1.655,-0.75*math.pi};
world.Lcorner[2]={3.69,-1.655,0.75*math.pi};
world.Lcorner[3]={-3.69,1.655,-0.25*math.pi};
world.Lcorner[4]={-3.69,-1.655,0.25*math.pi};
--Penalty box edge
world.Lcorner[5]={-3.23,0.575,-0.75*math.pi};
world.Lcorner[6]={-3.23,-0.575,0.75*math.pi};
world.Lcorner[7]={3.23,0.575,-0.25*math.pi};
world.Lcorner[8]={3.23,-0.575,0.25*math.pi};
--Penalty box T edge
world.Lcorner[9]={3.69,0.575,-0.75*math.pi};
world.Lcorner[10]={3.69,-0.575,0.75*math.pi};
world.Lcorner[11]={-3.69,0.575,-0.25*math.pi};
world.Lcorner[12]={-3.69,-0.575,0.25*math.pi};

world.Lcorner[13]={3.69,0.575,0.75*math.pi};
world.Lcorner[14]={3.69,-0.575,-0.75*math.pi};
world.Lcorner[15]={-3.69,0.575,0.25*math.pi};
world.Lcorner[16]={-3.69,-0.575,-0.25*math.pi};

--Center T edge
world.Lcorner[17]={0,1.655,-0.25*math.pi};
world.Lcorner[18]={0,1.655,-0.75*math.pi};
world.Lcorner[19]={0,-1.655,0.25*math.pi};
world.Lcorner[20]={0,-1.655,0.75*math.pi};

--Center Circle Junction
world.Lcorner[21]={0,0.805,-0.25*math.pi};
world.Lcorner[22]={0,0.805,0.25*math.pi};
world.Lcorner[23]={0,0.805,-0.75*math.pi};
world.Lcorner[24]={0,0.805,0.75*math.pi};
world.Lcorner[25]={0,-0.805,-0.25*math.pi};
world.Lcorner[26]={0,-0.805,0.25*math.pi};
world.Lcorner[27]={0,-0.805,-0.75*math.pi};
world.Lcorner[28]={0,-0.805,0.75*math.pi};

--constrain the goalie to only certain corners
world.Lgoalie_corner = {}
world.Lgoalie_corner[1] = world.Lcorner[5];
world.Lgoalie_corner[2] = world.Lcorner[6];
world.Lgoalie_corner[3] = world.Lcorner[11];
world.Lgoalie_corner[4] = world.Lcorner[12];
world.Lgoalie_corner[5] = world.Lcorner[15];
world.Lgoalie_corner[6] = world.Lcorner[16];

--T corners
world.Tcorner = {};
--Penalty box T corners
world.Tcorner[1]={3.69,0.575,math.pi};
world.Tcorner[2]={3.69,-0.575,math.pi};
world.Tcorner[3]={-3.69,0.575,0};
world.Tcorner[4]={-3.69,-0.575,0};
--cirlce T corners
world.Tcorner[5]={0,1.655,-0.5*math.pi};
world.Tcorner[6]={0,-1.655,0.5*math.pi};

--T corners for goalie
world.Tgoalie_corner = {};
--Penalty box T corners
world.Tgoalie_corner[1]=world.Tcorner[3];
world.Tgoalie_corner[2]=world.Tcorner[4];


--Sigma values for one landmark observation
world.rSigmaSingle1 = .15;
world.rSigmaSingle2 = .10;
world.aSigmaSingle = 20*math.pi/180;

--Sigma values for goal observation
world.rSigmaDouble1 = .25;
world.rSigmaDouble2 = .20;
world.aSigmaDouble = 20*math.pi/180;


--same-colored goalposts
world.use_same_colored_goal=1;

--should we use new triangulation?
world.use_new_goalposts=1;


--Player filter weights
if Config.game.playerID > 1 then
	--Two post observation
	world.rGoalFilter = 0;
	world.aGoalFilter = 0;

	--Single post observation
	world.rPostFilter = 0;
	world.aPostFilter = 0;

	--Single known post observation
	world.rPostFilter2 = 0;
	world.aPostFilter2 = 0;

	--Spot
	world.rSpotFilter = 0.01;
	world.aSpotFilter = 0.0001;

	--L Corner observation - bottom
	world.rLCornerFilterBtm = 0.02
	world.aLCornerFilterBtm = 0.01

	--T Corner observation - bottom
	world.rTCornerFilterBtm = 0.03;
	world.aTCornerFilterBtm = 0.01;

	--L Corner observation - top
	world.rLCornerFilterTop = 0.001;
	world.aLCornerFilterTop = 0.01;

	--T Corner observation - top
	world.rTCornerFilterTop = 0.001;
	world.aTCornerFilterTop = 0.01;

	--Top line observation
    world.rLineFilterTop = 0.0001
    world.aLineFilterTop = 0.005;

    --Bottom Line observation
    world.rLineFilterBtm = 0.01;
    world.aLineFilterBtm = 0.005;

	--Circle observation
	world.rCircleFilterTop = 0.005;
	world.aCircleFilterTop = 0.01;
        world.rCircleFilterBtm = 0.02;
        world.aCircleFilterBtm = 0.01;

else --for goalie
	--goal observation
	world.rGoalFilter = 0;
	world.aGoalFilter = 0;

	 --Single post observation
	 world.rPostFilter = 0;
	 world.aPostFilter = 0;

	 --Single known post observation
	 world.rPostFilter2 = 0;
	 world.aPostFilter2 = 0;

	 --Spot
	 world.rSpotFilter = 0.01;
	 world.aSpotFilter = 0.001;

	 --L Corner observation - bottom
	world.rLCornerFilterBtm = 0.01
	world.aLCornerFilterBtm = 0.01

	--T Corner observation - bottom
	world.rTCornerFilterBtm = 0.01;
	world.aTCornerFilterBtm = 0.01;

	--L Corner observation - top
	world.rLCornerFilterTop = 0;
	world.aLCornerFilterTop = 0;

	--T Corner observation - top
	world.rTCornerFilterTop = 0;
	world.aTCornerFilterTop = 0;

	--Top line observation
    world.rLineFilterTop = 0.0001;
    world.aLineFilterTop = 0.005;

    --Bottom Line observation
    world.rLineFilterBtm = 0.0001;
    world.aLineFilterBtm = 0.01;

	 --Circle observation
	world.rCircleFilterTop = 0;
	world.aCircleFilterTop = 0;
        world.rCircleFilterBtm = 0;
        world.aCircleFilterBtm = 0;
end

-- default positions for our kickoff
--_________________
--|    \  A /     |
--|     \__/      |
--|   S       D   |
--|      D2       |
--|     _____     |
--|____|__G__|____|
world.initPosition1={
  {3.69, 0},   --Goalie
  {0.4, 0}, --Attacker
  {1.5, 1.0}, --Defender
  {1.0, -1.0}, --Supporter
  {2.5, 0},  --Defender2
}
-- default positions for opponents' kickoff
--_________________
--|    \    /     |
--|     \__/      |
--|       A       |
--|   S   .   D   |
--|     _D2___    |
--|____|__G__|____|
world.initPosition2={
  {3.69, 0},   --Goalie
  {1, 0}, --Attacker
  {2.0, 1}, --Defender
  {2.0,-1}, --Supporter
  {3.0, -0.5}, --Defender2
}

--Set default positions for robots when set up on sidelines
--Left and right defined as facing towards opponents goal
--{xPos, yPos, Ang}
--      _________________
--      |    \    /     |
--      |     \__/      |
-- S(#4)|               |A(#2)
--      |       .       |
--D2(#5)|     _____     |D(#3)
--      |____|_____|____|G(#1)

world.initPositionSidelines={
  {3.69, 1.655,-math.pi/2}, --Player 1, goalie on field corner to right of goal
  {0.805, 1.655,-math.pi/2}, --Player 2, attacker aligned base of circle on the right side of goal
  {2.35, 1.655,-math.pi/2}, --Player 3, defender aligned with penalty cross on right side
  {0.805,-1.655, math.pi/2}, --Player 4, supporter aligned base of circle on the left side of goal
  {2.35,-1.655, math.pi/2}, --Player 5, defender2 aligned with penalty cross on left side
}

--parameters to specify deviation of robot placement at start
--Values[units] {dx[m], dy[m], da[rad]}
world.initPositionSidelinesSpread = {0.05, 0.05, 5*math.pi/180};

--parameters for bimodal distibution during manual placement
world.pCircle = {0.805,0,0};
world.dpCircle = {0.1,0.1,10*math.pi/180};
world.pLine = {3.9,0,0};
world.dpLine = {0.1,4.6,10*math.pi/180};
world.fraction = 0.75; -- there is a 3/4 chance we get placed on the line

--Goalie pose during manual placement
world.pGoalie = {3.69,0};
world.dpGoalie = {0.04,0.04,math.pi/8};

--How much noise to add to model while walking
--More means the particles will diverge quicker
world.daNoise = 0.5*math.pi/180;
world.drNoise = 0.02;

--can enable for debugging, forces localization to always re-initialize
-- to sideline position defined above
world.forceSidelinePos = 0;

-- use sound localization
world.enable_sound_localization = 0;

--Scales odometry {x, y, angle}
--old carpet
--world.odomScale = {1.15, 1, 1} --for walking forwards
--world.odomScale2 = {0.5, 1, 1} -- for walking backwards

--new turf
world.odomScale = {1.11, 1.15, 1} --for walking forwards
world.odomScale2 = {0.9, 1.15, 1} -- for walking backwards
--Various thresholds
world.angle_update_threshold = 3.0
world.angle_update_threshold_goalie = math.huge
world.triangulation_threshold = 4.0;
world.position_update_threshold = 6.0;
world.triangulation_threshold_goalie = 0;
world.position_update_threshold_goalie =0;
