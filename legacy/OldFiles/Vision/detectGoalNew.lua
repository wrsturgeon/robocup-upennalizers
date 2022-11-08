require('Config');	-- For Ball and Goal Size
require('ImageProc');
-- require('HeadTransform');  -- For Projection
require('Body')

--Use tilted boundingbox? (robots with nonzero bodytilt)
use_tilted_bbox = Config.vision.use_tilted_bbox or 0;
--Use center post to determine post type (disabled for OP)
use_centerpost=Config.vision.goal.use_centerpost or 0;
--Check the bottom of the post for green
check_for_ground = Config.vision.goal.check_for_ground or 0;
--Min height of goalpost (to reject false positives at the ground)
goal_height_min = Config.vision.goal.height_min or -0.5;

---Detects a goal of a given color.
--@param color The color to use for detection, represented by an int
--@return Table containing whether a ball was detected
--If a goal is detected, also contains additional stats about the goal


print("DFY:",Config.vision.goal.distanceFactorYellow)

if Config.game.playerID then
  distanceFactorYellow = Config.vision.goal.distanceFactorYellow or 1.0
else
  distanceFactorYellow = Config.vision.goal.distanceFactorYellowGoalie or 1
end

	
--Post dimension
postDiameter = Config.world.postDiameter or 0.10;
postHeight = Config.world.goalHeight or 0.80;
goalWidth = Config.world.goalWidth or 1.40;

--------------------------------------------------------------
--Vision threshold values (to support different resolutions)
--------------------------------------------------------------
th_min_color_count=Config.vision.goal.th_min_color_count;
th_min_area = Config.vision.goal.th_min_area;
th_nPostB = Config.vision.goal.th_nPostB;
th_min_orientation = Config.vision.goal.th_min_orientation;
th_min_fill_extent = Config.vision.goal.th_min_fill_extent;
th_aspect_ratio = Config.vision.goal.th_aspect_ratio;
th_edge_margin = Config.vision.goal.th_edge_margin;
th_bottom_boundingbox = Config.vision.goal.th_bottom_boundingbox;
th_ground_boundingbox = Config.vision.goal.th_ground_boundingbox;
th_min_green_ratio = Config.vision.goal.th_min_green_ratio;
th_goal_separation = Config.vision.goal.th_goal_separation;
th_min_area_unknown_post = Config.vision.goal.th_min_area_unknown_post;
scaleBGoal = Config.vision.scaleB;

--function detect(color)
local function update(self, color, labelA, labelB, colorCount, HT)
  local HeadTransform = HT
  self.debug_msg = ''
  self.detect = 0;

  local postB;

  if use_tilted_bbox>0 then
    --where shoud we update the roll angle? HeadTransform?
    tiltAngle = HeadTransform.getCameraRoll();
    vcm.set_camera_rollAngle(tiltAngle);

--Tilted labelB test for OP
------------------------------------------------------------------------


    self.labelBtilted.moffset = labelA.m/scaleBGoal/2;
    self.labelBtilted.m = labelA.m/scaleBGoal*2;
    self.labelBtilted.n = labelA.n/scaleBGoal;
    self.labelBtilted.npixel = self.labelBtilted.m*self.labelBtilted.n;

    self.labelBtilted.data = 
	ImageProc.tilted_block_bitor(labelA.data, 
	labelA.m, labelA.n, scaleBGoal, 
	scaleBGoal, tiltAngle);
    postB = ImageProc.goal_posts(self.labelBtilted.data, 
	self.labelBtilted.m, self.labelBtilted.n, color, th_nPostB);
    --discount tilt offset
    if postB then
      for i = 1,#postB do
        postB[i].boundingBox[1] = 
    	  postB[i].boundingBox[1]-self.labelBtilted.moffset;
        postB[i].boundingBox[2] = 
	  postB[i].boundingBox[2]-self.labelBtilted.moffset;
      end
    end
------------------------------------------------------------------------

  else
    tiltAngle=0;
    vcm.set_camera_rollAngle(tiltAngle);
    postB = ImageProc.goal_posts(labelB.data, 
    	labelB.m, labelB.n, color, th_nPostB);
  end

  if (not postB) then 	
    self:add_debug_message("No yellow region detected\n")
    return; 
  end

  local npost = 0;
  local ivalidB = {};
  local postA = {};
  -- self:add_debug_message(string.format("Checking %d posts\n",#postB));

  lower_factor = 0.3;

  for i = 1,#postB do
    local valid = true;

    --Check lower part of the goalpost for thickness
    
    if use_tilted_bbox>0 then
      self:add_debug_message("Use Tilted postStats\n");
      local bboxA = vcm.bboxStats(color,postB[i].boundingBox,tiltAngle,scaleBGoal);
      postStats = ImageProc.color_stats(labelA.data, labelA.m, 
                                        labelA.n, color, bboxA);
      boundingBoxLower={};
      boundingBoxLower[1],boundingBoxLower[2],
      boundingBoxLower[3],boundingBoxLower[4]=
        postB[i].boundingBox[1], postB[i].boundingBox[2],
        postB[i].boundingBox[3], postB[i].boundingBox[4];

      boundingBoxLower[3] = (1-lower_factor)* boundingBoxLower[3] + lower_factor*boundingBoxLower[4];
      local bboxA = vcm.bboxStats(color, postB[i].boundingBox,tiltAngle,scaleBGoal);
      postStatsLow = ImageProc.color_stats(labelA.data, labelA.m, 
                                        labelA.n, color, bboxA);
    else
      local bboxA = vcm.bboxStats(color,postB[i].boundingBox,_,scaleBGoal);
      postStats = ImageProc.color_stats(labelA.data, labelA.m, 
                                        labelA.n, color, bboxA);
      boundingBoxLower={};
      boundingBoxLower[1],boundingBoxLower[2],
      boundingBoxLower[3],boundingBoxLower[4]=
        postB[i].boundingBox[1], postB[i].boundingBox[2],
        postB[i].boundingBox[3], postB[i].boundingBox[4];
      boundingBoxLower[3] = (1-lower_factor)* boundingBoxLower[3] + lower_factor*boundingBoxLower[4];
      local bboxA = vcm.bboxStats(color, postB[i].boundingBox,tiltAngle,scaleBGoal);
      postStatsLow = ImageProc.color_stats(labelA.data, labelA.m, 
                                        labelA.n, color, bboxA);
    end

--[[    
    --REDUCE POST WIDTH 
    --TODO: This seems to make crashing sometimes
    self:add_debug_message(string.format(
	"Thickness: full %.1f lower:%.1f\n",
	postStats.axisMinor,postStatsLow.axisMinor));
    widthRatio = postStats.axisMinor / postStatsLow.axisMinor;
    if widthRatio < 2.0 then
      postStats.axisMinor = math.min(
	postStats.axisMinor, postStatsLow.axisMinor)
    end
--]]
    -- size and orientation check
    if (postStats.area < th_min_area) then
      self:add_debug_message(string.format("FAIL area check: %f < %d\n",postStats.area, th_min_area));
      valid = false;
    end

    if valid then
      local orientation= postStats.orientation - tiltAngle;
      if (math.abs(orientation) < th_min_orientation) then
        self:add_debug_message(string.format("FAIL orientation check: %.1f < %.1f\n", 
        	 180*orientation/math.pi, th_min_orientation/math.pi*180));
        valid = false;
      end
    end
      
    --fill extent check
    if valid then
      local fill_rate = postStats.area / (postStats.axisMajor * postStats.axisMinor);
      if (fill_rate < th_min_fill_extent) then 
        self:add_debug_message(string.format("FAIL fill rate check: %.2f < %.2f\n", 
          fill_rate, th_min_fill_extent));
        valid = false; 
      end
    end

    --aspect ratio check
    if valid then
      local aspect = postStats.axisMajor/postStats.axisMinor;
      if (aspect < th_aspect_ratio[1]) or (aspect > th_aspect_ratio[2]) then 
        self:add_debug_message(string.format("FAIL aspect check: %.1f\n",aspect));
        valid = false; 
      end
    end

    --check edge margin
    if valid then
      local leftPoint= postStats.centroid[1] - 
        postStats.axisMinor/2 * math.abs(math.cos(tiltAngle));
      local rightPoint= postStats.centroid[1] + 
      	postStats.axisMinor/2 * math.abs(math.cos(tiltAngle));

      local margin = math.min(leftPoint,labelA.m-rightPoint);
      if margin<=th_edge_margin then
        self:add_debug_message(string.format("FAIL edge margin check: %d < %d\n",
          margin, th_edge_margin));
        valid = false;
      end

    end

    -- ground check at the bottom of the post
    if valid and check_for_ground>0 then 
      local bboxA = vcm.bboxB2A(postB[i].boundingBox, Config.vision.scaleB);
      if (bboxA[4] < th_bottom_boundingbox * labelA.n) then

        -- field bounding box 
        local fieldBBox = {};
        fieldBBox[1] = bboxA[1] + th_ground_boundingbox[1];
        fieldBBox[2] = bboxA[2] + th_ground_boundingbox[2];
        fieldBBox[3] = bboxA[4] + th_ground_boundingbox[3];
        fieldBBox[4] = bboxA[4] + th_ground_boundingbox[4];

        local fieldBBoxStats;
      	if use_tilted_bbox>0 then
              -- color stats for the bbox
               fieldBBoxStats = ImageProc.tilted_color_stats(labelA.data, 
      		labelA.m,labelA.n, Config.color.field,fieldBBox,tiltAngle);
      	else
               fieldBBoxStats = ImageProc.color_stats(labelA.data, 
      		labelA.m,labelA.n, Config.color.field,fieldBBox,tiltAngle);
      	end
        local fieldBBoxArea = vcm.bboxArea(fieldBBox);

      	green_ratio=fieldBBoxStats.area/fieldBBoxArea;

        -- is there green under the goal post?
        if (green_ratio<th_min_green_ratio) then
          self:add_debug_message(string.format(
        		"FAIL green ratio check: %.2f < %.2f\n",green_ratio, th_min_green_ratio));
          valid = false;
        end
      end
    end

    if valid then
      --Height Check
      local scale = math.sqrt(postStats.area / (postDiameter*postHeight) );
      v = HeadTransform.coordinatesA(postStats.centroid, scale);
      if v[3] < goal_height_min then
        self:add_debug_message(string.format("FAIL height check:%.2f < %.2f\n",
          v[3], goal_height_min));
        valid = false; 
      end
    end

    if valid then
      ivalidB[#ivalidB + 1] = i;
      npost = npost + 1;
      postA[npost] = postStats;
    end
  end

  if ((npost < 1) or (npost > 2)) then 
    self:add_debug_message(string.format("Post number failure %d\n", npost));
    return 
  end

  self.propsB = {};
  self.propsA = {};
  self.v = {};

  for i = 1,npost do
    self.propsB[i] = postB[ivalidB[i]];
    self.propsA[i] = postA[i];

    local scale1 = postA[i].axisMinor / postDiameter;
    local scale2 = postA[i].axisMajor / postHeight;
    local scale3 = math.sqrt(postA[i].area / (postDiameter*postHeight) );

    if self.propsB[i].boundingBox[3]<2 then 
      --This post is touching the top, so we can only use diameter
      self:add_debug_message("Post touching the top\n");
      scale = math.max(scale1);
    else
      scale = math.max(scale1,scale2,scale3);
    end


--SJ: goal distance can be noisy, so I added bunch of debug message here
    local v1 = HeadTransform.coordinatesA(postA[i].centroid, scale1);
    local v2 = HeadTransform.coordinatesA(postA[i].centroid, scale2);
    local v3 = HeadTransform.coordinatesA(postA[i].centroid, scale3);
    --[[
    self:add_debug_message(string.format("Distance by width : %.1f\n",
	math.sqrt(v1[1]^2+v1[2]^2) ));
    self:add_debug_message(string.format("Distance by height : %.1f\n",
	math.sqrt(v2[1]^2+v2[2]^2) ));
    self:add_debug_message(string.format("Distance by area : %.1f\n",
	math.sqrt(v3[1]^2+v3[2]^2) ));
    --]]

    if scale==scale1 then
      self:add_debug_message("Post distance measured by width\n");
      self.v[i] = v1;
    elseif scale==scale2 then
      self:add_debug_message("Post distance measured by height\n");
      self.v[i] = v2;
    else
      self:add_debug_message("Post distance measured by area\n");
      self.v[i] = v3;
    end

    self.v[i][1]=self.v[i][1]*distanceFactorYellow;
    self.v[i][2]=self.v[i][2]*distanceFactorYellow;

    self:add_debug_message(string.format("post[%d] = %.2f %.2f %.2f\n",
	 i, self.v[i][1], self.v[i][2], self.v[i][3]));
  end

  if (npost == 2) then
    self.type = 3; --Two posts

--Do we need this? this may hinder detecting goals when robot is facing down...
--[[
    -- check for valid separation between posts:
    local dGoal = postA[2].centroid[1]-postA[1].centroid[1];
    local dPost = math.max(postA[1].axisMajor, postA[2].axisMajor);
    local separation=dGoal/dPost;
    self:add_debug_message(string.format(
	"Two goal separation:%f\n",separation))
    if (separation<th_goal_separation[1] or 
        separation>th_goal_separation[2]) then
      self:add_debug_message("Goal separation check fail\n")
      return goal;
    end
--]]

  else
    self.v[2] = vector.new({0,0,0,0});

    -- look for crossbar:
    local postWidth = postA[1].axisMinor;

    local leftX = postA[1].boundingBox[1]-5*postWidth;
    local rightX = postA[1].boundingBox[2]+5*postWidth;
    local topY = postA[1].boundingBox[3]-5*postWidth;
    local bottomY = postA[1].boundingBox[3]+5*postWidth;
    local bboxA = {leftX, rightX, topY, bottomY};

    local crossbarStats = ImageProc.color_stats(labelA.data, labelA.m, labelA.n, color, bboxA,tiltAngle);
    local dxCrossbar = crossbarStats.centroid[1] - postA[1].centroid[1];
    local crossbar_ratio = dxCrossbar/postWidth; 

    self:add_debug_message(string.format(
	"Crossbar stat: %.2f\n",crossbar_ratio));

    --If the post touches the top, it should be a unknown post
    if self.propsB[1].boundingBox[3]<3 then --touching the top
      dxCrossbar = 0; --Should be unknown post
    end

    if (math.abs(dxCrossbar) > 0.6*postWidth) then
      if (dxCrossbar > 0) then
      	if use_centerpost>0 then
      	  self.type = 1;  -- left post
      	else
      	  self.type = 0;  -- unknown post
      	end
      else
      	if use_centerpost>0 then
      	  self.type = 2;  -- right post
      	else
      	  self.type = 0;  -- unknown post
      	end
      end
    else
      -- unknown post
      self.type = 0;
        -- eliminate small posts without cross bars      
      if (postA[1].area < th_min_area_unknown_post) then
        self:add_debug_message("Unknown post size too small");
        return
      end

    end
  end
  
  -- added for test_vision.m
  -- --TODO: get rid of this
  -- if Config.vision.copy_image_to_shm then
  --     vcm.set_goal_postBoundingBox1(postB[ivalidB[1]].boundingBox);
  --     vcm.set_goal_postCentroid1({postA[1].centroid[1],postA[1].centroid[2]});
  --     vcm.set_goal_postAxis1({postA[1].axisMajor,postA[1].axisMinor});
  --     vcm.set_goal_postOrientation1(postA[1].orientation);
  --     if npost == 2 then
  --       vcm.set_goal_postBoundingBox2(postB[ivalidB[2]].boundingBox);
  --       vcm.set_goal_postCentroid2({postA[2].centroid[1],postA[2].centroid[2]});
  --       vcm.set_goal_postAxis2({postA[2].axisMajor,postA[2].axisMinor});
  --       vcm.set_goal_postOrientation2(postA[2].orientation);
  --     else
  --       vcm.set_goal_postBoundingBox2({0,0,0,0});
  --     end
  -- end

  if self.type==0 then
    self:add_debug_message(string.format("Unknown single post detected\n"));
  elseif self.type==1 then
    self:add_debug_message(string.format("Left post detected\n"));
  elseif self.type==2 then
    self:add_debug_message(string.format("Right post detected\n"));
  elseif self.type==3 then
    self:add_debug_message(string.format("Two posts detected\n"));
  end

  self.detect = 1;
  return
end

-- local update_shm = function(self)
--   vcm.set_goal_detect(self.detect);
--   if (self.detect == 1) then
--     vcm.set_goal_color(Config.color.yellow);
--     vcm.set_goal_type(self.type);
--     vcm.set_goal_v1(self.v[1]);
--     vcm.set_goal_v2(self.v[2]);
--   end
-- end

local add_debug_message = function(self, str)
  self.debug_msg = self.debug_msg..str
end

local detectGoal = {}
function detectGoal.entry()
  print('init Goal detection')
  local self = {}
  self.update = update
  self.update_shm = update_shm
  self.add_debug_message = add_debug_message

  self.detect = 0
  self.debug_msg = ''
  self.labelBtilted = {}
  
  return self
end

return detectGoal
