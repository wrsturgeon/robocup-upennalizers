require('Config');      -- For Ball and Goal Size
require('ImageProc');
-- require('HeadTransform');       -- For Projection
require('Body');
require('vcm');
require('mcm');

local check_for_ground = Config.vision.ball.check_for_ground;
local check_for_field = Config.vision.ball.check_for_field or 0;
local field_margin = Config.vision.ball.field_margin or 0;
--function detect(color)

local enable_obs_challenge = Config.obs_challenge or 0;


---Detects a ball of a given color.
--@param color The color to use for detection, represented by an int
--@return Table containing whether a ball was detected
--If a ball is detected, also contains additional stats about the ball
local update = function(self, color, labelA, labelB, colorCount, cidx, HT)
  local HeadTransform = HT
  self.debug_msg = ''

  local headAngle = Body.get_head_position();
--  print("headPitch:",headAngle[2]*180/math.pi);
  self.detect = 0;

  -- threshold check on the total number of ball pixels in the image
  if (colorCount[color] < self.th_min_color) then  	
    self:add_debug_message(string.format("Ball %d: pixel count FAIL: %d < %d\n", cidx,
    colorCount[color], self.th_min_color ));
    return
  end
  self.color_count = colorCount[color];

  -- find connected components of ball pixels
  local ballPropsB = ImageProc.connected_regions(
    labelB.data, labelB.m, 
    labelB.n, color);

  --TODO: horizon cutout
  -- ballPropsB = ImageProc.connected_regions(labelB.data, labelB.m, 
  --	labelB.n, HeadTransform.get_horizonB(),color);

  if (not ballPropsB or #ballPropsB == 0) then return end

  -- Check max 5 largest blobs 
  local check_passed, v
  for i=1,math.min(5,#ballPropsB) do
    self:add_debug_message(string.format("Ball: checking blob %d/%d\n",i,#ballPropsB));

    check_passed = true;
    self.propsB = ballPropsB[i];
    -- TODO: NOT USING VCM
    local bboxA = vcm.bboxStats(color, ballPropsB[i].boundingBox, _, self.scaleB);
    self.propsA = ImageProc.color_stats(labelA.data, labelA.m, 
                                        labelA.n, color, bboxA);

    self.bboxA = vcm.bboxB2A(ballPropsB[i].boundingBox, self.scaleB);

    if self.propsA.area < self.th_min_color2 then
      --Area check
      self:add_debug_message("Area check fail\n");
      check_passed = false;
    end
    if check_passed then
      local fill_rate = self.propsA.area / vcm.bboxArea(self.propsA.boundingBox);
      if fill_rate < self.th_min_fill_rate then
        --Fill rate check
        self:add_debug_message("Fillrate check fail\n");
        check_passed = false;
      end
    end
    if check_passed then
      local aspect_ratio = self.propsA.axisMajor / self.propsA.axisMinor
      --TODO: put into Config...
      if aspect_ratio>4 or aspect_ratio<0.25 then
        self:add_debug_message('Aspect ratio check fail\n')
        check_passed = false
      end
    end
    if check_passed then
      -- diameter of the area
      local dArea = math.sqrt((4/math.pi)* self.propsA.area);
      -- Find the centroid of the ball
      local ballCentroid = self.propsA.centroid;
      -- Coordinates of ball
      local scale = math.max(dArea/self.diameter, self.propsA.axisMajor/self.diameter);
      v = HeadTransform.coordinatesA(ballCentroid, scale);
      v_inf = HeadTransform.coordinatesA(ballCentroid,0.1);
      
      -- self:add_debug_message(string.format("Ball v0: %.2f %.2f %.2f\n",v[1],v[2],v[3]));

      --Global ball position check
      local pose = wcm.get_pose();
      local posexya=vector.new( {pose.x, pose.y, pose.a} );
      local ballGlobal=util.pose_global({v[1],v[2],0},posexya);
      local pos_check_fail = false;

      if ballGlobal[1]>Config.world.xMax * self.fieldsize_factor or
       ballGlobal[1]<-Config.world.xMax * self.fieldsize_factor or
       ballGlobal[2]>Config.world.yMax * self.fieldsize_factor or
       ballGlobal[2]<-Config.world.yMax * self.fieldsize_factor then
        pos_check_fail = true;
        self:add_debug_message("On-the-field check fail\n");
      end

      if pos_check_fail and
         (v[1]*v[1] + v[2]*v[2] > self.max_distance*self.max_distance) then
       	--Only check distance if the ball is out of field
        self:add_debug_message("Distance check fail\n");
        check_passed = false;
      elseif v[3] > self.th_height_max then
        --Ball height check
        self:add_debug_message("Height check fail\n");
        check_passed = false;
      end

      if check_passed and check_for_ground>0 then
        -- ground check
        -- is ball cut off at the bottom of the image?
        local vmargin = labelA.n-ballCentroid[2];
        self:add_debug_message("Bottom margin check\n");
        self:add_debug_message(string.format( "lableA height: %d, centroid Y: %d diameter: %.1f\n",
  	                                              labelA.n, ballCentroid[2], dArea ));
        --When robot looks down they may fail to pass the green check
        --So increase the bottom margin threshold
        if vmargin > dArea * 2.0 then
          -- bounding box below the ball
          local fieldBBox = {};
          fieldBBox[1] = ballCentroid[1] + self.th_ground_boundingbox[1];
          fieldBBox[2] = ballCentroid[1] + self.th_ground_boundingbox[2];
          fieldBBox[3] = ballCentroid[2] + .5*dArea + self.th_ground_boundingbox[3];
          fieldBBox[4] = ballCentroid[2] + .5*dArea + self.th_ground_boundingbox[4];
          -- color stats for the bbox
          local fieldBBoxStats = ImageProc.color_stats(labelA.data, 
  	                            labelA.m, labelA.n, Config.color.field, fieldBBox);
          if (fieldBBoxStats.area < self.th_min_green1) then
            -- if there is no field under the ball 
      	    -- it may be because its on a white line
            local whiteBBoxStats = ImageProc.color_stats(labelA.data,
 	                              labelA.m, labelA.n, Config.color.white, fieldBBox);
            if (whiteBBoxStats.area < self.th_min_green2) then
              self:add_debug_message(string.format("Green check fail %d %d\n", 
                                            whiteBBoxStats.area, self.th_min_green2));
              check_passed = false;
            end
          end --end white line check
        end --end bottom margin check
      end --End ball height, ground check
    end --End all check

    if check_passed then    
      local ballv = {v[1],v[2],0};
      local pose=wcm.get_pose();
      local posexya=vector.new( {pose.x, pose.y, pose.a} );
      local ballGlobal = util.pose_global(ballv,posexya); 
      if check_for_field>0 then
        if math.abs(ballGlobal[1]) > Config.world.xLineBoundary + field_margin or
          math.abs(ballGlobal[2]) > Config.world.yLineBoundary + field_margin then
          self:add_debug_message("Field check fail\n");
          check_passed = false;
        end
      end
    end
    if check_passed then
      break;
    end
  end --End loop

  if not check_passed then
    return
  end
  
  --SJ: Projecting ball to flat ground makes large distance error
  --We are using declined plane for projection

  local vMag =math.max(0,math.sqrt(v[1]^2+v[2]^2)-0.50);
  local bodyTilt = vcm.get_camera_bodyTilt();
--  print("BodyTilt:",bodyTilt*180/math.pi)
  local projHeight = vMag * math.tan(10*math.pi/180);


  local v=HeadTransform.projectGround(v,self.diameter/2-projHeight);

  --SJ: we subtract foot offset 
  --bc we use ball.x for kick alignment
  --and the distance from foot is important
  v[1]=v[1]-mcm.get_footX()

  local ball_shift = Config.ball_shift or {0,0};
  --Compensate for camera tilt
  v[1]=v[1] + ball_shift[1];
  v[2]=v[2] + ball_shift[2];

  --Ball position ignoring ball size (for distant ball observation)
  local v_inf=HeadTransform.projectGround(v_inf,self.diameter/2);
  v_inf[1]=v_inf[1]-mcm.get_footX()
  wcm.set_ball_v_inf({v_inf[1],v_inf[2]});  

  self.v = v;
  self.detect = 1;
  self.r = math.sqrt(self.v[1]^2 + self.v[2]^2);

  -- How much to update the particle filter
  self.dr = 0.25*self.r;
  self.da = 10*math.pi/180;

  self:add_debug_message(string.format(
	"Ball detected\nv: %.2f %.2f %.2f\n",v[1],v[2],v[3]));
--[[
  print(string.format(
	"Ball detected\nv: %.2f %.2f %.2f\n",v[1],v[2],v[3]));
--]]

  return
end

--[[
local update_shm = function(self, p_vision)
  local cidx = p_vision.camera_index
  vcm['set_ball'..cidx..'_detect'](self.detect);
  if (self.detect == 1) then
    vcm['set_ball'..cidx..'_color_count'](self.color_count);
    vcm['set_ball'..cidx..'_centroid'](self.propsA.centroid);
    vcm['set_ball'..cidx..'_axisMajor'](self.propsA.axisMajor);
    vcm['set_ball'..cidx..'_axisMinor'](self.propsA.axisMinor);
    vcm['set_ball'..cidx..'_v'](self.v);
    vcm['set_ball'..cidx..'_r'](self.r);
    vcm['set_ball'..cidx..'_dr'](self.dr);
    vcm['set_ball'..cidx..'_da'](self.da);
  end
end
--]]

local add_debug_message = function(self, str)
  self.debug_msg = self.debug_msg..str
end


local detectBall = {}

function detectBall.entry(cidx)
  print('init Ball detection')
  local self = {}
  self.update = update
  self.update_shm = update_shm
  self.add_debug_message = add_debug_message
  self.detect = 0
  self.debug_msg = ''

  self.diameter = Config.vision.ball.diameter;
  self.th_min_color=Config.vision.ball.th_min_color[cidx];
  self.th_min_color2=Config.vision.ball.th_min_color2[cidx];
  self.th_min_fill_rate=Config.vision.ball.th_min_fill_rate;
  self.th_height_max=Config.vision.ball.th_height_max;
  self.th_ground_boundingbox=Config.vision.ball.th_ground_boundingbox[cidx];
  self.th_min_green1=Config.vision.ball.th_min_green1[cidx];
  self.th_min_green2=Config.vision.ball.th_min_green2[cidx];
  self.th_headAngle = Config.vision.ball.th_headAngle or -10*math.pi/180;
  self.max_distance = Config.vision.ball.max_distance or 5.0;
  self.fieldsize_factor = Config.vision.ball.fieldsize_factor or 2.0;
  self.scaleA = Config.vision.scaleA
  self.scaleB = Config.vision.scaleB

  return self
end

return detectBall
