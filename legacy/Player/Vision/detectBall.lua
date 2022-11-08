require('Config');      -- For Ball and Goal Size require('ImageProc');
require('HeadTransform');       -- For Projection
require('Body');
require('vcm');
require('mcm');

bottom_boudary_check = Config.vision.ball.bottom_boudary_check or 0
ball_check_for_ground = Config.vision.ball.check_for_ground;
check_for_field = Config.vision.ball.check_for_field or 0;
field_margin = Config.vision.ball.field_margin or 0;

---Detects a ball of a given color.
--@param color The color to use for detection, represented by an int
--@return Table containing whether a ball was detected
--If a ball is detected, also contains additional stats about the ball
local update = function(self, color, line_info, p_vision)
  local colorCount = p_vision.colorCount;
  headAngle = Body.get_head_position();
  local top_camera = false
  self.detect = 0;
  self.on_line = 0;
  --p_vision:add_debug_message(string.format("\nBall %d: pixel count: %d\n", p_vision.camera_index,
  --JZ    colorCount[color] ));
  --  print(string.format("\nBall: pixel count: %d\n", colorCount[color]));
  -- threshold check on the total number of ball pixels in the image
  --if (colorCount[color] < self.th_min_color) then
  --  p_vision:add_debug_message("pixel count fail");
  --  return
  --end
  self.color_count = colorCount[color];

  -- Find connected components of ball pixels
  local ballPropsB;
  if p_vision.camera_index==1 then top_camera=true end
  ballPropsB = ImageProc.connected_regions(p_vision.labelB.data, p_vision.labelB.m, p_vision.labelB.n, Config.color.white);
  if (not ballPropsB or #ballPropsB == 0) then return end
  if top_camera then
    p_vision:add_debug_message('===Top Ball check===\n')
  else
    p_vision:add_debug_message('===Bottom Ball check===\n');
    -- db: HeadTransform.projectGround testing, should be fixed now
    -- local v = {1, 1};
    -- local v_FixedHeight = HeadTransform.coordinatesFixedHeight(v, 0.1);
    -- local v_ProjectGround = HeadTransform.projectGround(HeadTransform.coordinatesA(v, 1), 0.1);
    -- table.foreach(v_FixedHeight, function(k, v) p_vision:add_debug_message(string.format(k..": %.3f, ", v)) end);
    -- p_vision:add_debug_message("\n");
    -- table.foreach(v_ProjectGround, function(k, v) p_vision:add_debug_message(string.format(k..": %.3f, ", v)) end);
    -- p_vision:add_debug_message("\n")
  end
  local check_passed
  -- Check all blobs until hit a ball that no longer passes area check

  if top_camera==false then
    --the number is PURELY a hack --Dickens
    horizonboundary = math.max(math.min(1.2*(math.abs(headAngle[1])-0.5),1),0)
    bottomboundary = math.max(0, -1.9*headAngle[2])*p_vision.labelA.n
    if headAngle[1] > 0 then
      leftboundary = horizonboundary*p_vision.labelA.m
      rightboundary = p_vision.labelA.m
    else
      leftboundary = 0
      rightboundary = (1-horizonboundary)*p_vision.labelA.m
    end
    if(math.abs(headAngle[1])>math.pi/3) then
      --print("L vs R vs B: "..leftboundary.." "..rightboundary.." "..bottomboundary)
    end
  end

  for i=1,#ballPropsB do
    check_passed = true;
    if check_passed then
      -- Add one more check to filter out jersey ball on bottom camera
      -- p_vision:add_debug_message(string.format("Ball: checking blob %d/%d\n",i,#ballPropsB));
      self.propsB = ballPropsB[i];
      -- p_vision:add_debug_message(string.format("(%.2f, %.2f), (%.2f, %.2f)\n", ballPropsB[i].boundingBox[1], ballPropsB[i].boundingBox[3], ballPropsB[i].boundingBox[2], ballPropsB[i].boundingBox[4]));
      local bboxA = vcm.bboxB2A(ballPropsB[i].boundingBox, p_vision.scaleB);
      self.propsA = ImageProc.color_stats(p_vision.labelA.data, p_vision.labelA.m, p_vision.labelA.n, Config.color.white, bboxA);
      self.bboxA = bboxA
      if top_camera == false and bottom_boudary_check == 1 then
        if math.abs(headAngle[1])>math.pi/3 then
          if (self.propsA.centroid[1]<leftboundary or self.propsA.centroid[2]>rightboundary)
            and self.propsA.centroid[2]>bottomboundary then
            check_passed = false;
            --print ("centroid: "..self.propsA.centroid[1].." "..self.propsA.centroid[2].."\n");
            --p_vision:add_debug_message(string.format("Failure: Boundary Problem \n"));
          end
        end
      end

      -- FILTER OUR THE WRONG BALL BASED ON DIFFERENT CHECKS
      -- Defining variables
      local aspect_ratio = self.propsA.axisMajor / self.propsA.axisMinor
      if (self.propsA.axisMinor == 0) then aspect_ratio = self.propsA.axisMajor / 0.00001 end
        --p_vision:add_debug_message(string.format('aspect ratio %.4f \n', aspect_ratio));

      local props_black = ImageProc.color_stats(p_vision.labelA.data, p_vision.labelA.m, p_vision.labelA.n, Config.color.orange, bboxA);
      local props_cyan = ImageProc.color_stats(p_vision.labelA.data, p_vision.labelA.m, p_vision.labelA.n, Config.color.cyan, bboxA); -- not used
      local black_rate =  props_black.area / self.propsA.area
      local fill_rate = (self.propsA.area + props_black.area) / vcm.bboxArea(self.propsA.boundingBox)
      -- p_vision:add_debug_message(string.format('black ratio %.4f \n', black_rate));
      -- p_vision:add_debug_message(string.format('black area %.4f \n', props_black.area));
      -- p_vision:add_debug_message(string.format('Fill rate %.4f \n', fill_rate));
      -- p_vision:add_debug_message(string.format('ball area %.4f \n', self.propsA.area));

      if top_camera == false then
          th_min_fill_rate = self.th_min_fill_rate_btm;
          th_min_black_rate = self.th_min_black_rate_btm;
      elseif top_camera == true then
          th_min_fill_rate = self.th_min_fill_rate_top;
          th_min_black_rate = self.th_min_black_rate_top;
      end

      -- p_vision:add_debug_message(string.format("Black ratio %.4f < %.2f fail\n", black_rate, th_min_black_rate));

      -- CHECKS
      -- p_vision:add_debug_message(string.format('ball area %.4f \n',self.propsA.area));
      -- if self.propsA.area < 46 then
      --   p_vision:add_debug_message(string.format('Proposed Ball %d\n', i));
      --   p_vision:add_debug_message(string.format('Ball area: %.4f\n', self.propsA.area));
      --   p_vision:add_debug_message(string.format('Fill rate: %.4f\n', fill_rate));
      --   p_vision:add_debug_message(string.format('Aspect ratio: %.4f\n', aspect_ratio));
      --   p_vision:add_debug_message(string.format('Black ratio: %.4f\n', black_rate));
      --   p_vision:add_debug_message(string.format('Black area: %.4f\n\n', props_black.area));
        -- p_vision:add_debug_message(string.format('Screen position: (%d, %d)\n', self.propsA.boundingBox[1], self.propsA.boundingBox[3]));
      -- end
      if self.propsA.area > self.th_max_color2 then  --Max color check
        --p_vision:add_debug_message('Ball area '..self.propsA.area..'>'..self.th_max_color2..' fail\n');
        check_passed = false;
      elseif self.propsA.area < self.th_min_color2 then --Min color check
        --p_vision:add_debug_message('Ball area '..self.propsA.area..'<'..self.th_min_color2..' fail\n');
        check_passed = false;
        --print('min area failed '..self.propsA.area..' minimum was '..self.th_min_color2)
      else
        -- next check
      end

      --p_vision:add_debug_message(string.format("self.bboxA: (%d, %d), (%d, %d)\n", self.bboxA[1], self.bboxA[3], self.bboxA[2], self.bboxA[4]));
      if check_passed then
        if fill_rate < th_min_fill_rate then      --Fill rate check
          --p_vision:add_debug_message(string.format('Fill rate %.4f < %.2f fail\n',fill_rate,th_min_fill_rate));
          check_passed = false;
        -- elseif fill_rate > self.th_max_fill_rate then
        --   p_vision:add_debug_message(string.format('Fill rate %.4f > %.2f fail\n', fill_rate, self.th_max_fill_rate));
        --   check_passed = false;
        elseif self.propsA.boundingBox[4] < HeadTransform.get_horizonA() then
           --p_vision:add_debug_message(string.format('Horizon check fail'));
          check_passed = false;
        elseif aspect_ratio > self.th_max_aspect_ratio then -- aspect ratio check
           --p_vision:add_debug_message(string.format('Aspect ratio %.4f > %.2f fail\n',aspect_ratio, self.th_max_aspect_ratio));
          check_passed = false;
        elseif aspect_ratio < self.th_min_aspect_ratio then
           --p_vision:add_debug_message(string.format('Aspect ratio %.4f < %.2f fail\n', aspect_ratio, self.th_min_aspect_ratio));
          check_passed = false;
        elseif black_rate < th_min_black_rate then -- black ratio check
          --p_vision:add_debug_message(string.format("Black ratio %.4f < %.2f fail\n", black_rate, th_min_black_rate));
          check_passed = false;
        elseif black_rate > self.th_max_black_rate then
           --p_vision:add_debug_message(string.format("Black ratio %.4f > %.2f fail\n", black_rate, self.th_max_black_rate));
          check_passed = false;
        elseif props_black.area < self.th_min_black_area then -- min black area check
          --p_vision:add_debug_message(string.format("Black area %.4f < %.2f fail\n", props_black.area, self.th_min_black_area));
          check_passed = false;
        else
          --Now we have somewhat solid blob somewhere. Get the position of it
          local dArea = math.sqrt((4/math.pi)* self.propsA.area);-- diameter of the area
          local ballCentroid = self.propsA.centroid;-- Find the centroid of the ball
          local scale = math.max(dArea/self.diameter, self.propsA.axisMajor/self.diameter)
          v = HeadTransform.coordinatesA(ballCentroid, scale) -- Coordinates of ball
          v_inf = HeadTransform.coordinatesA(ballCentroid,0.1) --far-projected coordinate of the ball

          -- p_vision:add_debug_message(string.format("Ball v0: %.2f %.2f %.2f\n",v[1],v[2],v[3]));
          -- p_vision:add_debug_message(string.format("Scale: %.2f\n", scale));
          -- p_vision:add_debug_message(string.format("Ball centroid: (%.2f, %.2f)\n", ballCentroid[1], ballCentroid[2]));

          if top_camera == false and check_passed then
              if v[3] < self.min_height_btm or v[3] > self.max_height_btm then
                  --p_vision:add_debug_message(string.format("Height %.4f not within (%.2f, %.2f) fail\n", v[3], self.min_height_btm, self.max_height_btm));
                  check_passed = false
              end
          end

          if top_camera == true and check_passed then
            if v[3] < self.min_height_top or v[3] > self.max_height_top then
              check_passed = false
              --p_vision:add_debug_message(string.format("Height %.4f not within (%.2f, %.2f) fail\n", v[3], self.min_height_top, self.max_height_top));
            end
          end

          if top_camera and check_passed then
            --Horizon check
            --print('passed ball: '..math.sqrt(v[1]*v[1] + v[2]*v[2])..' height is '..v[3])
            -- Distance - height check
            exp_height = 0.0764*math.sqrt(v[1]*v[1] + v[2]*v[2])
            height_diff = math.abs(v[3] - exp_height)
            local height_err = 0.20
            --[[ if math.abs(v[3]) > exp_height and false then
               -- print('reached new distance height check')
               -- print('distance is'..math.sqrt(v[1]*v[1] + v[2]*v[2]))
               -- print('height diff '..height_diff..' height err is '..height_err)
                p_vision:add_debug_message('Height-distance check fail\n')
                check_passed=false;
            else
               -- print('height_diff passed'..height_diff)
            end    ]]--
            ball_dist_inf = math.sqrt(v_inf[1]*v_inf[1] + v_inf[2]*v_inf[2])
            height_th_inf = self.th_height_max + ball_dist_inf * math.tan(10*math.pi/180)
            if v_inf[3] > height_th_inf then
               -- p_vision:add_debug_message(string.format('Horizon check fail, %.2f>%.2f\n',v_inf[3],height_th_inf));
               check_passed = false;
            end

            --Global ball position check
            pose = wcm.get_pose();
            posexya=vector.new( {pose.x, pose.y, pose.a} );
            ballGlobal=util.pose_global({v[1],v[2],0},posexya);
            if ballGlobal[1]>Config.world.xMax * self.fieldsize_factor or
               ballGlobal[1]<-Config.world.xMax * self.fieldsize_factor or
               ballGlobal[2]>Config.world.yMax * self.fieldsize_factor or
               ballGlobal[2]<-Config.world.yMax * self.fieldsize_factor then
              if (v[1]*v[1] + v[2]*v[2] > self.max_distance*self.max_distance) then
                --p_vision:add_debug_message("On-the-field check fail\n");
                check_passed = false;
              end
            end
            --Ball height check
            local ball_dist = math.sqrt(v[1]*v[1] + v[2]*v[2])
            local height_th = self.th_height_max + ball_dist * math.tan(8*math.pi/180)
            if check_passed and v[3] > 0.3 then
                 -- print('v3 is '..v[3])
                 -- print('reached')
           	   -- p_vision:add_debug_message(string.format('Failure: Ball Height Check Fail \n'));
  		       check_passed = false
            end
            -- local height_th = self.th_height_max + ball_dist * math.tan(3*math.pi/180)
            -- if check_passed and v[3] > 0.07 then
            --       check_passed = false
            -- end

            -- p_vision:add_debug_message(string.format('Height check: %.2f / %.2f\n',v[3],height_th))
            if check_passed and v[3] > height_th then
              -- p_vision:add_debug_message(string.format('Height check fail\n',v[3],height_th))
              check_passed = false;
            end
          end --End top camera check

          --print('reached for cam')
          if check_passed then          --Pink check (ball in jersey)
            if ball_check_for_ground>0  then  -- ground check
              -- is ball cut off at the bottom of the image?
              local vmargin=p_vision.labelA.n-ballCentroid[2];
              local hmargin=p_vision.labelA.m-ballCentroid[1];
              --if vmargin > dArea * 2.0 then  -- bounding box below the ball

              if ((ballCentroid[1] > dArea and top_camera) or (ballCentroid[1] > dArea / 2 and not top_camera)) then
                local fieldBBox_left = {}
                -- p_vision:add_debug_message(string.format("centroid:%d %d %d\n",ballCentroid[1],ballCentroid[2],.5*dArea));
                fieldBBox_left[1] = ballCentroid[1] - .5*dArea + self.th_ground_boundingbox[1];
                fieldBBox_left[2] = ballCentroid[1] - .5*dArea;
                fieldBBox_left[3] = ballCentroid[2] - .5*dArea;
                fieldBBox_left[4]= ballCentroid[2] + .5*dArea;
                -- local left_area = (fieldBBox_left[2]-fieldBBox_left[1])*(fieldBBox_left[4]-fieldBBox_left[3]);
                local left_area = vcm.bboxArea(fieldBBox_left);

                local fieldBBoxStats_left = ImageProc.color_stats(p_vision.labelA.data, p_vision.labelA.m, p_vision.labelA.n, Config.color.field, fieldBBox_left);
                -- p_vision:add_debug_message(string.format("Green check left:%.2f %.2f\n", fieldBBoxStats_left.area/left_area, self.th_min_green1));

                if (fieldBBoxStats_left.area/left_area < self.th_min_green1) then
                  --p_vision:add_debug_message(string.format("Failure: left green check\n"));
  				        check_passed = false;
                end
              else
                check_passed = false;
              end
              if ((hmargin > dArea and top_camera) or (hmargin > dArea / 2)) and check_passed then
                local fieldBBox_right = {}
                fieldBBox_right[1] = ballCentroid[1] + .5*dArea;
                fieldBBox_right[2] = ballCentroid[1] + .5*dArea + self.th_ground_boundingbox[2];
                fieldBBox_right[3] = ballCentroid[2] - .5*dArea;
                fieldBBox_right[4] = ballCentroid[2] + .5*dArea;
                -- local right_area = (fieldBBox_right[2]-fieldBBox_right[1])*(fieldBBox_right[4]-fieldBBox_right[3]);
                local right_area = vcm.bboxArea(fieldBBox_right);
                local fieldBBoxStats_right = ImageProc.color_stats(p_vision.labelA.data, p_vision.labelA.m, p_vision.labelA.n, Config.color.field, fieldBBox_right);
                -- p_vision:add_debug_message(string.format("Green check right:%.2f %.2f\n", fieldBBoxStats_right.area/right_area, self.th_min_green1));

                if (fieldBBoxStats_right.area/right_area < self.th_min_green1) then
                  --p_vision:add_debug_message(string.format("Failure: right green check\n"));
                  check_passed = false;
                end
              else
                check_passed = false;
              end

              if ((ballCentroid[2] > dArea and top_camera) or (ballCentroid[2] > dArea / 2 and not top_camera)) and check_passed then
                local fieldBBox_top = {}
                fieldBBox_top[1] = ballCentroid[1] - .5*dArea;
                fieldBBox_top[2] = ballCentroid[1] + .5*dArea;
                fieldBBox_top[3] = ballCentroid[2] - .5*dArea + self.th_ground_boundingbox[3];
                fieldBBox_top[4] = ballCentroid[2] - .5*dArea;
                -- local top_green_area = (fieldBBox_top[2]-fieldBBox_top[1])*(fieldBBox_top[4]-fieldBBox_top[3]);
                local top_green_area = vcm.bboxArea(fieldBBox_top);

                local fieldBBoxStats_top = ImageProc.color_stats(p_vision.labelA.data, p_vision.labelA.m, p_vision.labelA.n, Config.color.field, fieldBBox_top);
                -- p_vision:add_debug_message(string.format("Green check top:%.2f %.2f\n", fieldBBoxStats_top.area/top_green_area, self.th_min_green1));
                if (fieldBBoxStats_top.area/top_green_area < self.th_min_green1) then
                  --p_vision:add_debug_message(string.format("Failure: top green check\n"));
  				        check_passed = false;
                end
              else
                check_passed = false;
              end

              if vmargin > dArea and check_passed and false then  -- BOTTOM GREEN CHECK COMPLETELY DISABLED
                local fieldBBox_btm = {}
                fieldBBox_btm[1] = ballCentroid[1] - .5*dArea;
                fieldBBox_btm[2] = ballCentroid[1] + .5*dArea;
                fieldBBox_btm[3] = ballCentroid[2] + .5*dArea;
                fieldBBox_btm[4] = ballCentroid[2] + .5*dArea + self.th_ground_boundingbox[4];

                -- local btm_green_area = (fieldBBox_btm[2]-fieldBBox_btm[1])*(fieldBBox_btm[4]-fieldBBox_btm[3]);
                local btm_green_area = vcm.bboxArea(fieldBBox_btm);

                local fieldBBoxStats_btm = ImageProc.color_stats(p_vision.labelA.data, p_vision.labelA.m, p_vision.labelA.n, Config.color.field, fieldBBox_btm);
                --p_vision:add_debug_message(string.format("Green check btm: %.2f %.2f\n", fieldBBoxStats_btm.area/btm_green_area, self.th_min_green2));
                if (fieldBBoxStats_btm.area/btm_green_area < self.th_min_green2) then
                  -- bottom may cast some shadow
                  --p_vision:add_debug_message(string.format("Failure: bottom green check\n"));
                  check_passed = false;
                end
              else
                --do nothing
              end
            end
            --     local fieldBBox = {};
             --   fieldBBox[1] = ballCentroid[1] + .5*dArea + self.th_ground_boundingbox[1];
               -- fieldBBox[2] = ballCentroid[1] + .5*dArea + self.th_ground_boundingbox[2];
              --  fieldBBox[3] = ballCentroid[2] + .5*dArea + self.th_ground_boundingbox[3];
              --  fieldBBox[4] = ballCentroid[2] + .5*dArea + self.th_ground_boundingbox[4];
                -- color stats for the bbox
              --  local fieldBBoxStats = ImageProc.color_stats(p_vision.labelA.data, p_vision.labelA.m, p_vision.labelA.n, Config.color.field, fieldBBox);
              --  p_vision:add_debug_message(string.format("Green check:%d %d\n", fieldBBoxStats.area, self.th_min_green1));
               -- if (fieldBBoxStats.area < self.th_min_green1) then
                  -- if there is no field under the ball
                  -- it may be because its on a white line
                 -- local whiteBBoxStats = ImageProc.color_stats(p_vision.labelA.data,
                   -- p_vision.labelA.m, p_vision.labelA.n, Config.color.white, fieldBBox);
                 -- if (whiteBBoxStats.area < self.th_min_green2) then
                   -- p_vision:add_debug_message(string.format(
                     -- "Green check fail %d %d\n", whiteBBoxStats.area, self.th_min_green2));
                   -- check_passed = false;
                --  end
              --  end --end white line check
             -- end --end bottom margin check
            -- end --End ball height, ground check
            local props_green = ImageProc.color_stats(p_vision.labelA.data,p_vision.labelA.m, p_vision.labelA.n, self.field, bboxA);
            local fill_rate_undefined = 1 - (self.propsA.area + props_black.area + props_green.area) / vcm.bboxArea(self.propsA.boundingBox);
            --p_vision:add_debug_message(string.format("Fill rate undefined: %.2f (max: %.2f)\n", fill_rate_undefined, self.th_max_fill_rate_undefined));
            if fill_rate_undefined > self.th_max_fill_rate_undefined then
              --p_vision:add_debug_message(string.format("Fill rate undefined fail: %.2f (max: %.2f)\n", fill_rate_undefined, self.th_max_fill_rate_undefined));
              check_passed = false;
            end
          end

          -- centroid check -- disabled
          -- if check_passed then -- check for the centroid of the black area and check against centroid of white area
          --   local x_centroid_dist = (ballCentroid[1] - props_black.centroid[1])
          --   local y_centroid_dist = (ballCentroid[2] - props_black.centroid[2])
          --   local centroid_dist = math.sqrt(x_centroid_dist*x_centroid_dist + y_centroid_dist*y_centroid_dist)
            -- p_vision:add_debug_message(string.format("White centroid: (%.2f, %.2f)\n", ballCentroid[1], ballCentroid[2]));
            -- p_vision:add_debug_message(string.format("Black centroid: (%.2f, %.2f)\n", props_black.centroid[1], props_black.centroid[2]));
            --p_vision:add_debug_message(string.format("Centroid distance: %.2f\n", centroid_dist));
             --p_vision:add_debug_message(string.format("Centroid dist.: %.2f (max: %.2f)\n", centroid_dist, self.max_centroid_dist));
            -- if centroid_dist > self.max_centroid_dist then
               --p_vision:add_debug_message(string.format("Centroid dist. fail: %.2f (max: %.2f)\n", centroid_dist, self.max_centroid_dist));
          --     check_passed = false;
          --   end
          -- end
          -- if check_passed == true and top_camera then
           -- print('height'..v[3]..'allowed'..exp_height)
           -- print('distance'..math.sqrt(v[1]*v[1]+v[2]*v[2]))
          -- end
        end --End all check
      end
    end --End top camera
    if check_passed then break end
  end --End propsB loop


  -----------------------------------------------------------------------------------------
  -------------------------- BALL ON LINE DETECTION ---------------------------------------
  -----------------------------------------------------------------------------------------

  if not check_passed and line_info and self.enable_BallOnLine_detection then

  -----------------------------------------------------------------------------------------
  -------------------------- BoL: Define local functions
  -----------------------------------------------------------------------------------------
    p_vision:add_debug_message(string.format(" Checking ball on line: "));
    local nLines = line_info["nLines"];
    local endpoint = line_info["endpoint"];
    local v_line = line_info["v"];

    local function getBallDiameterAtA(x, y)
      local v_obs = HeadTransform.coordinatesA({x, y}, 1);
      local v_actual = HeadTransform.projectGround(v_obs, self.diameter/2);
      return self.diameter*((v_obs[3] - HeadTransform.getCameraOffset()[3])/(v_actual[3] - HeadTransform.getCameraOffset()[3]));
    end

    local function getBallDiameterAtB(x, y)
      local v_obs = HeadTransform.coordinatesB({x, y}, 1);
      local v_actual = HeadTransform.projectGround(v_obs, self.diameter/2);
      return self.diameter*((v_obs[3] - HeadTransform.getCameraOffset()[3])/(v_actual[3] - HeadTransform.getCameraOffset()[3]));
    end

    local function checkForBall(bboxB)
      -----------------------------------------------------------------------------------------
      -- 1. Calculate fill rate and black rate around provided bbox and perform checks
      -----------------------------------------------------------------------------------------
      local bboxA = vcm.bboxB2A(bboxB, p_vision.scaleB);
      -- p_vision:add_debug_message(string.format("bboxA: (%d, %d), (%d, %d)\n", bboxA[1], bboxA[3], bboxA[2], bboxA[4]));
      local props_white = ImageProc.color_stats(p_vision.labelA.data, p_vision.labelA.m, p_vision.labelA.n, Config.color.white, bboxA);
      local props_black = ImageProc.color_stats(p_vision.labelA.data, p_vision.labelA.m, p_vision.labelA.n, Config.color.orange, bboxA);

      if props_white.area == 0 then
        -- p_vision:add_debug_message(string.format("BoL props_white.area == 0 (1)\n"));
        return false
      end
      if props_black.area == 0 then
        -- p_vision:add_debug_message(string.format("BoL props_black.area == 0 (1)\n"));
        return false
      end

      local fill_rate = (props_white.area + props_black.area) / vcm.bboxArea(bboxA);
      local black_rate =  props_black.area / props_white.area;

      if fill_rate < self.BoL_min_fill_rate or fill_rate > self.BoL_max_fill_rate then
        p_vision:add_debug_message(string.format("bboxA: (%d, %d), (%d, %d) ", bboxA[1], bboxA[3], bboxA[2], bboxA[4]));
        p_vision:add_debug_message(string.format("BoL Fill rate: %.2f fail (%.2f - %.2f) ", fill_rate, self.BoL_min_fill_rate, self.BoL_max_fill_rate));
        return false
      end
      if black_rate < (center_min_black_rate or self.BoL_min_black_rate) or black_rate > self.BoL_max_black_rate then
        p_vision:add_debug_message(string.format("bboxA: (%d, %d), (%d, %d) ", bboxA[1], bboxA[3], bboxA[2], bboxA[4]));
        p_vision:add_debug_message(string.format("BoL Black rate: %.2f fail (%.2f - %.2f) ", black_rate, self.BoL_min_black_rate, self.BoL_max_black_rate));
        return false
      end

      -----------------------------------------------------------------------------------------
      -- 2. Refine bboxA around the black area's centroid (in a two step process of finding centroid and recentering)
      -----------------------------------------------------------------------------------------
      local props_centroid = props_black.centroid;
      local props_ballDiameter = getBallDiameterAtA(props_centroid[1], props_centroid[2]);
      bboxA = {};
      bboxA[1] = props_centroid[1] - (props_ballDiameter/2 + 10);
      bboxA[2] = props_centroid[1] + (props_ballDiameter/2 + 10);
      bboxA[3] = props_centroid[2] - (props_ballDiameter/2 + 10);
      bboxA[4] = props_centroid[2] + (props_ballDiameter/2 + 10);
      props_black = ImageProc.color_stats(p_vision.labelA.data, p_vision.labelA.m, p_vision.labelA.n, Config.color.orange, bboxA);
      if props_black.area == 0 then
        -- p_vision:add_debug_message(string.format("BoL props_black.area == 0 (2)\n"));
        return false
      end
      props_centroid = props_black.centroid;
      props_ballDiameter = getBallDiameterAtA(props_centroid[1], props_centroid[2]);
      local props_v = HeadTransform.projectGround(HeadTransform.coordinatesA(props_centroid, 1), self.diameter/2);
      bboxA = {};
      bboxA[1] = props_centroid[1] - (props_ballDiameter/2 * 1.05);
      bboxA[2] = props_centroid[1] + (props_ballDiameter/2 * 1.05);
      bboxA[3] = props_centroid[2] - (props_ballDiameter/2 * 1.05);
      bboxA[4] = props_centroid[2] + (props_ballDiameter/2 * 1.05);

      if bboxA[1] < -3 or bboxA[2] > self.BoL_max_x_axis_value or bboxA[3] < -3 then
        -- p_vision:add_debug_message(string.format("BoL bboxA[1]or[3] < -3 or bboxA[2] > max_x_axis_value "));
        -- p_vision:add_debug_message(string.format("bboxA: (%d, %d), (%d, %d) ", bboxA[1], bboxA[3], bboxA[2], bboxA[4]));
        return false
      end
      --p_vision:add_debug_message(string.format("refined bboxA: (%d, %d), (%d, %d)\n", bboxA[1], bboxA[3], bboxA[2], bboxA[4]))

      -----------------------------------------------------------------------------------------
      -- 3. Calculate fill rate, black rate on refined bboxA with basic nonzero checks
      -----------------------------------------------------------------------------------------

      props_white = ImageProc.color_stats(p_vision.labelA.data, p_vision.labelA.m, p_vision.labelA.n, Config.color.white, bboxA);
      props_black = ImageProc.color_stats(p_vision.labelA.data, p_vision.labelA.m, p_vision.labelA.n, Config.color.orange, bboxA);
      if props_white.area == 0 then
        -- p_vision:add_debug_message(string.format("BoL props_white.area == 0 (3)\n"));
        return false
      end
      if props_black.area == 0 then
        -- p_vision:add_debug_message(string.format("BoL props_black.area == 0 (3)\n"));
        return false
      end
      local refined_fill_rate = (props_white.area + props_black.area) / vcm.bboxArea(bboxA);
      local refined_black_rate =  props_black.area / props_white.area;

      -----------------------------------------------------------------------------------------
      -- 4. Calculate bboxB of same area and fill rate and black rate with basic nonzero checks
      -----------------------------------------------------------------------------------------

      bboxB = vcm.bboxB2A(bboxA, 1/p_vision.scaleB);
      -- p_vision:add_debug_message(string.format("refined bboxB: (%d, %d), (%d, %d)\n", bboxB[1], bboxB[3], bboxB[2], bboxB[4]))

      props_white_B = ImageProc.color_stats(p_vision.labelB.data, p_vision.labelB.m, p_vision.labelB.n, Config.color.white, bboxB);
      props_black_B = ImageProc.color_stats(p_vision.labelB.data, p_vision.labelB.m, p_vision.labelB.n, Config.color.orange, bboxB);
      if props_white_B.area == 0 then
        -- p_vision:add_debug_message(string.format("BoL props_white.area == 0 (3)\n"));
        return false
      end
      if props_black_B.area == 0 then
        -- p_vision:add_debug_message(string.format("BoL props_black.area == 0 (3)\n"));
        return false
      end

      local fill_rate_B = (props_white_B.area + props_black_B.area) / vcm.bboxArea(bboxB);
      local black_rate_B =  props_black_B.area / props_white_B.area;

      -----------------------------------------------------------------------------------------
      -- 5. Perform checks of the refined bboxA (black rate, fill rate, horizon, height, undefined rate)
      -----------------------------------------------------------------------------------------

      if refined_fill_rate < self.BoL_min_refined_fill_rate or refined_fill_rate > self.BoL_max_refined_fill_rate then
        p_vision:add_debug_message(string.format("bboxA: (%d, %d), (%d, %d) ", bboxA[1], bboxA[3], bboxA[2], bboxA[4]));
        p_vision:add_debug_message(string.format("BoL refined_fill_rate bad: %.2f (%.2f - %.2f) ", refined_fill_rate, self.BoL_min_refined_fill_rate, self.BoL_max_refined_fill_rate))
        return false
      end

      if refined_black_rate < self.BoL_min_refined_black_rate or refined_black_rate > self.BoL_max_refined_black_rate then
        p_vision:add_debug_message(string.format("bboxA: (%d, %d), (%d, %d) ", bboxA[1], bboxA[3], bboxA[2], bboxA[4]));
        p_vision:add_debug_message(string.format("BoL refined_black_rate bad: %.2f (%.2f - %.2f) ", refined_black_rate, self.BoL_min_refined_black_rate, self.BoL_max_refined_black_rate))
        return false
      end

      if props_white.boundingBox[4] < HeadTransform.get_horizonA() then
        -- p_vision:add_debug_message(string.format("BoL Horizon fail\n"));
        check_passed = false;
        return false;
      end

      local dArea = math.sqrt((4/math.pi)* props_white.area);-- diameter of the area
      local ballCentroid = props_white.centroid;-- Find the centroid of the ball
      local scale = math.max(dArea/self.diameter, props_white.axisMajor/self.diameter)
      v = HeadTransform.coordinatesA(ballCentroid, scale) -- Coordinates of ball
      v_inf = HeadTransform.coordinatesA(ballCentroid,0.1) --far-projected coordinate of the ball
      if v[3] < self.BoL_min_height or v[3] > self.BoL_max_height then
          p_vision:add_debug_message(string.format("bboxA: (%d, %d), (%d, %d) ", bboxA[1], bboxA[3], bboxA[2], bboxA[4]));
          p_vision:add_debug_message(string.format("BoL height fail: %.2f (%.2f - %.2f) ", v[3], self.BoL_min_height, self.BoL_max_height));
          check_passed = false
          return false;
      end

      props_green = ImageProc.color_stats(p_vision.labelA.data, p_vision.labelA.m, p_vision.labelA.n, Config.color.field, bboxA);


      local fill_rate_undefined = 1 - (props_white.area+props_black.area+props_green.area) / vcm.bboxArea(bboxA);

      if fill_rate_undefined > self.BoL_max_fill_rate_undefined then
        p_vision:add_debug_message(string.format("bboxA: (%d, %d), (%d, %d) ", bboxA[1], bboxA[3], bboxA[2], bboxA[4]));
        p_vision:add_debug_message(string.format("BoL undefined fill rate fail: %.2f (max: %.2f) ", fill_rate_undefined, self.BoL_max_fill_rate_undefined));
        return false;
      end

      -- centroid check -- disabled
      -- local x_centroid_dist = (props_white.centroid[1] - props_black.centroid[1])
      -- local y_centroid_dist = (props_white.centroid[2] - props_black.centroid[2])
      -- local centroid_dist = math.sqrt(x_centroid_dist*x_centroid_dist + y_centroid_dist*y_centroid_dist)
      -- p_vision:add_debug_message(string.format("BoL: white centroid: (%.2f, %.2f)\n", props_white.centroid[1], props_white.centroid[2]));
      -- p_vision:add_debug_message(string.format("BoL: black centroid: (%.2f, %.2f)\n", props_black.centroid[1], props_black.centroid[2]));
      -- p_vision:add_debug_message(string.format("BoL: centroid distance: %.2f\n", centroid_dist));
      -- if centroid_dist > self.BoL_max_centroid_dist then
      --   p_vision:add_debug_message(string.format("bboxA: (%d, %d), (%d, %d) ", bboxA[1], bboxA[3], bboxA[2], bboxA[4]));
      --   p_vision:add_debug_message(string.format("BoL centroid dist. fail: %.2f (max: %.2f) ", centroid_dist, self.BoL_max_centroid_dist));
      --   return false;
      -- end

      -----------------------------------------------------------------------------------------
      -- 6. Perform checks of the bboxB (black rate, fill rate)
      -----------------------------------------------------------------------------------------
      if fill_rate_B < self.BoL_min_fill_rate_B or fill_rate_B > self.BoL_max_fill_rate_B then
        p_vision:add_debug_message(string.format("bboxA: (%d, %d), (%d, %d)\n", bboxA[1], bboxA[3], bboxA[2], bboxA[4]));
        p_vision:add_debug_message(string.format("BoL fill_rate_B bad: %.2f (%.2f - %.2f) ",fill_rate_B, self.BoL_min_fill_rate_B, self.BoL_max_fill_rate_B))
        return false
      end

      if props_v[1] < 0.9 then
        if black_rate_B < self.BoL_min_black_rate_B or black_rate_B > self.BoL_max_black_rate_B then
          p_vision:add_debug_message(string.format("bboxA: (%d, %d), (%d, %d)\n", bboxA[1], bboxA[3], bboxA[2], bboxA[4]));
          p_vision:add_debug_message(string.format("BoL black_rate_B bad1: %.2f (%.2f - %.2f) ", black_rate_B, self.BoL_min_black_rate_B, self.BoL_max_black_rate_B))
          return false
        end
      else
        if black_rate_B < self.BoL_min_black_rate_B_far or black_rate_B > self.BoL_max_black_rate_B then
          p_vision:add_debug_message(string.format("bboxA: (%d, %d), (%d, %d) ", bboxA[1], bboxA[3], bboxA[2], bboxA[4]));
          p_vision:add_debug_message(string.format("BoL black_rate_B bad2: %.2f (%.2f - %.2f) ", black_rate_B, self.BoL_min_black_rate_B_far, self.BoL_max_black_rate_B))
          return false
        end
      end

      -----------------------------------------------------------------------------------------
      -- 7. Calculate bboxs above and below refined bboxA to check green rate
      -----------------------------------------------------------------------------------------
      bboxA_above = {};
      bboxA_above[1] = props_black.boundingBox[1];
      bboxA_above[2] = props_black.boundingBox[2];
      bboxA_above[3] = math.max(props_white.boundingBox[3] - 15, self.BoL_min_y_axis_value);
      bboxA_above[4] = props_white.boundingBox[3];

      bboxA_below = {};
      bboxA_below[1] = props_black.boundingBox[1];
      bboxA_below[2] = props_black.boundingBox[2];
      bboxA_below[3] = props_white.boundingBox[4];
      bboxA_below[4] = math.min(props_white.boundingBox[4] + 15, self.BoL_max_y_axis_value);

      -- print(string.format("above: (%d, %d), (%d, %d)", bboxA_above[1], bboxA_above[3], bboxA_above[2], bboxA_above[4]));
      -- print(string.format("below: (%d, %d), (%d, %d)", bboxA_below[1], bboxA_below[3], bboxA_below[2], bboxA_below[4]));

      local green_above = ImageProc.color_stats(p_vision.labelA.data, p_vision.labelA.m, p_vision.labelA.n, Config.color.field, bboxA_above);
      local green_below = ImageProc.color_stats(p_vision.labelA.data, p_vision.labelA.m, p_vision.labelA.n, Config.color.field, bboxA_below);

      local green_rate_above = green_above.area / vcm.bboxArea(bboxA_above);
      local green_rate_below = green_below.area / vcm.bboxArea(bboxA_below);

      if green_rate_above < self.BoL_min_green_rate_above_alone then
        if green_rate_above < self.BoL_min_green_rate_above then
          p_vision:add_debug_message(string.format("bboxA: (%d, %d), (%d, %d) ", bboxA[1], bboxA[3], bboxA[2], bboxA[4]));
          p_vision:add_debug_message(string.format("BoL green_rate_above bad: %.2f (min: %.2f) ", green_rate_above, self.BoL_min_green_rate_above))
          return false
        end
        if green_rate_below < self.BoL_min_green_rate_below then
          p_vision:add_debug_message(string.format("bboxA: (%d, %d), (%d, %d) ", bboxA[1], bboxA[3], bboxA[2], bboxA[4]));
          p_vision:add_debug_message(string.format("BoL green_rate_below bad: %.2f (min: %.2f) ", green_rate_below, self.BoL_min_green_rate_below))
          return false
        end
      end

      self.propsA = {};
      self.propsA.centroid = props_centroid;
      self.propsA.axisMajor = props_ballDiameter;
      self.propsA.axisMinor = 0;

      v = props_v;
      v_inf = HeadTransform.coordinatesA(self.propsA.centroid, 0.1);

      -----------------------------------------------------------------------------------------
      -- 8. Print out ball detected information (for use of real and false positives)
      -----------------------------------------------------------------------------------------
      -- p_vision:add_debug_message(string.format("BoL Fill rate: %.2f (%.2f - %.2f)\n", fill_rate, self.BoL_min_fill_rate, self.BoL_max_fill_rate));
      -- p_vision:add_debug_message(string.format("BoL Black rate: %.2f (%.2f - %.2f)\n", black_rate, self.BoL_min_black_rate, self.BoL_max_black_rate));
      -- p_vision:add_debug_message(string.format("BoL refined_fill_rate: %.2f (%.2f - %.2f)\n", refined_fill_rate, self.BoL_min_refined_fill_rate, self.BoL_max_refined_fill_rate));
      -- p_vision:add_debug_message(string.format("BoL refined_black_rate: %.2f (%.2f - %.2f)\n", refined_black_rate, self.BoL_min_refined_black_rate, self.BoL_max_refined_black_rate));
      -- p_vision:add_debug_message(string.format("BoL fill_rate_B: %.2f (%.2f - %.2f)\n",fill_rate_B, self.BoL_min_fill_rate_B, self.BoL_max_fill_rate_B));
      -- p_vision:add_debug_message(string.format("BoL black_rate_B: %.2f (%.2f - %.2f)\n", black_rate_B, self.BoL_min_black_rate_B, self.BoL_max_black_rate_B))
      -- p_vision:add_debug_message(string.format("BoL green_rate_above: %.2f (min: %.2f)\n", green_rate_above, self.BoL_min_green_rate_above));
      -- p_vision:add_debug_message(string.format("BoL green_rate_below: %.2f (min: %.2f)\n", green_rate_below, self.BoL_min_green_rate_below));
      -- p_vision:add_debug_message(string.format("BoL height: %.2f (%.2f - %.2f)\n", v[3], self.BoL_min_height, self.BoL_max_height));
      -- p_vision:add_debug_message(string.format("BoL undefined rate: %.2f (max: %.2f)\n", fill_rate_undefined, self.BoL_max_fill_rate_undefined));
      -- p_vision:add_debug_message(string.format("BoL: centroid distance: %.2f\n", centroid_dist));

      return true
    end
    --------------------------BoL: End of local functions definition ---------------


    -----------------------------------------------------------------------------------------
    --------------------------BALL ON LINE DETECTION: Iteration over the lines detected -----
    -----------------------------------------------------------------------------------------

    --local first_ballFound = false; -- if line is short, requires the ball to be found twice (once on each side)
    for i=1,nLines do
      -- Not sure if lines consistently have endpoint[1] < endpoint[2], aka lines are entered left to right,
      -- so do following to guarantee correctness.
      local leftX = 0;
      local leftY = 0;
      local leftSize = 0;
      local rightX = 0;
      local rightY = 0;
      local rightSize = 0;

      if endpoint[i][1] <= endpoint[i][2] then
        leftX = endpoint[i][1];
        leftY = endpoint[i][3];
        rightX = endpoint[i][2];
        rightY = endpoint[i][4];
      else
        leftX = endpoint[i][2];
        leftY = endpoint[i][4];
        rightX = endpoint[i][1];
        rightY = endpoint[i][3];
      end

      leftSize = 0.75*getBallDiameterAtB(leftX, leftY);
      rightSize = 0.75*getBallDiameterAtB(rightX, rightY);
      centerSize = getBallDiameterAtB((rightX + leftX) / 2, (rightY + leftY) / 2);

      -- print(leftX, leftY, leftSize);
      -- print(rightX, rightY, rightSize);

      local leftbboxB = {};
      leftbboxB[1] = math.max(leftX - leftSize, self.BoL_min_x_axis_value);
      leftbboxB[2] = math.max(leftX, leftSize);
      leftbboxB[3] = math.max(leftY - leftSize, self.BoL_min_y_axis_value);
      leftbboxB[4] = math.min(leftY + leftSize, self.BoL_max_y_axis_value);

      local rightbboxB = {};
      rightbboxB[1] = rightX;
      rightbboxB[2] = math.min(rightX + rightSize, self.BoL_max_x_axis_value);
      rightbboxB[3] = math.max(rightY - rightSize, self.BoL_min_y_axis_value);
      rightbboxB[4] = math.min(rightY + rightSize, self.BoL_max_y_axis_value);

      local centerbboxB = {}
      centerbboxB[1] = (rightX + leftX) / 2 - centerSize / 2;
      centerbboxB[2] = (rightX + leftX) / 2 + centerSize / 2;
      centerbboxB[3] = (rightY + leftY) / 2 - centerSize;
      centerbboxB[4] = (rightY + leftY) / 2 + centerSize;

      local pixel_length = math.sqrt((rightX - leftX)*(rightX - leftX) + (rightY - leftY)*(rightY - leftY));

      if pixel_length > 15 then -- get rid of the lots of small false lines
        --p_vision:add_debug_message(string.format("Line of pixel size: %d\n", pixel_length));
        local ballFound = checkForBall(leftbboxB);
        if not ballFound then
          ballFound = checkForBall(rightbboxB);
        end
        -- p_vision:add_debug_message(math.sqrt((rightX - leftX)*(rightX - leftX) + (rightY - leftY)*(rightY - leftY)).."\n");
        if not ballFound and pixel_length > 50 then
  				--center_min_black_rate = 0.05;
          center_min_black_rate = self.BoL_min_black_rate;
          ballFound = checkForBall(centerbboxB);
  				center_min_black_rate = nil;
        end

        if ballFound then
          p_vision:add_debug_message(string.format("BoL detected: TRUE\n"));
          check_passed = true;
          self.on_line = 1;
          break
        end
      else
        --print('line segments too small')
      end
    end
  end

  --------------------------END OF BALL ON LINE DETECTION---------------------------------------


  if not check_passed then return end

  --SJ: we subtract foot offset
  --bc we use ball.x for kick alignment
  --and the distance from foot is important
  v[1]=v[1]-mcm.get_footX()
  local ball_shift = Config.ball_shift or {0,0}   --Compensate for camera tilt
  v[1]=v[1] + ball_shift[1]
  v[2]=v[2] + ball_shift[2]

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

  p_vision:add_debug_message(string.format("Ball detected\nv: %.2f %.2f %.2f\n",v[1],v[2],v[3]));
  return
end

local update_shm = function(self, p_vision)
  local cidx = p_vision.camera_index
  vcm['set_ball'..cidx..'_detect'](self.detect);
  if (self.detect == 1) then
    vcm['set_ball'..cidx..'_on_line'](self.on_line);
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


local detectBall = {}

function detectBall.entry(parent_vision)
  print('init Ball detection')
  local cidx = parent_vision.camera_index;
  local self = {}
  self.update = update;
  self.update_shm = update_shm;
  self.detect = 0;
  self.on_line = 1;
  self.diameter = Config.vision.ball.diameter;
  self.th_min_color=Config.vision.ball.th_min_color[cidx];
  self.th_min_color2=Config.vision.ball.th_min_color2[cidx];
  self.th_max_color2=Config.vision.ball.th_max_color2[cidx];
  self.th_min_fill_rate_top=Config.vision.ball.th_min_fill_rate_top;
  self.th_min_fill_rate_btm=Config.vision.ball.th_min_fill_rate_btm;
  self.th_max_fill_rate=Config.vision.ball.th_max_fill_rate;
  self.th_min_black_rate_top=Config.vision.ball.th_min_black_rate_top;
  self.th_min_black_rate_btm=Config.vision.ball.th_min_black_rate_btm;
  self.th_max_black_rate=Config.vision.ball.th_max_black_rate;
  self.th_height_max=Config.vision.ball.th_height_max;
  self.th_ground_boundingbox=Config.vision.ball.th_ground_boundingbox[cidx];
  self.th_min_green1=Config.vision.ball.th_min_green1[cidx];
  self.th_min_green2=Config.vision.ball.th_min_green2[cidx];
  self.th_headAngle = Config.vision.ball.th_headAngle or -10*math.pi/180;
  self.max_distance = Config.vision.ball.max_distance or 2.5;
  self.fieldsize_factor = Config.vision.ball.fieldsize_factor or 2.0;
  self.th_max_fill_rate_pink = Config.vision.ball.th_max_fill_rate_pink;
  self.jersey = Config.vision.ball.pink;
  self.th_max_aspect_ratio = Config.vision.ball.th_max_aspect_ratio;
  self.th_min_aspect_ratio = Config.vision.ball.th_min_aspect_ratio;
  self.th_min_black_rate = Config.vision.ball.th_min_black_rate;
  self.th_min_black_area = Config.vision.ball.th_min_black_area;
  self.min_height_btm = Config.vision.ball.min_height_btm;
  self.max_height_btm = Config.vision.ball.max_height_btm;
  self.min_height_top = Config.vision.ball.min_height_top;
  self.max_height_top = Config.vision.ball.max_height_top;
  self.enable_BallOnLine_detection = Config.vision.enable_BallOnLine_detection[cidx];
  self.BoL_min_fill_rate = Config.vision.ball.BoL_min_fill_rate[cidx];
  self.BoL_max_fill_rate = Config.vision.ball.BoL_max_fill_rate[cidx];
  self.BoL_min_black_rate = Config.vision.ball.BoL_min_black_rate[cidx];
  self.BoL_max_black_rate =Config.vision.ball.BoL_max_black_rate[cidx];
  self.BoL_min_refined_fill_rate = Config.vision.ball.BoL_min_refined_fill_rate[cidx];
  self.BoL_max_refined_fill_rate = Config.vision.ball.BoL_max_refined_fill_rate[cidx];
  self.BoL_min_refined_black_rate = Config.vision.ball.BoL_min_refined_black_rate[cidx];
  self.BoL_max_refined_black_rate = Config.vision.ball.BoL_max_refined_black_rate[cidx];
  self.BoL_min_fill_rate_B = Config.vision.ball.BoL_min_fill_rate_B[cidx];
  self.BoL_max_fill_rate_B = Config.vision.ball.BoL_max_fill_rate_B[cidx];
  self.BoL_min_black_rate_B = Config.vision.ball.BoL_min_black_rate_B[cidx];
  self.BoL_min_black_rate_B_far = Config.vision.ball.BoL_min_black_rate_B_far[cidx];
  self.BoL_max_black_rate_B = Config.vision.ball.BoL_max_black_rate_B[cidx];
  self.BoL_min_green_rate_below = Config.vision.ball.BoL_min_green_rate_below[cidx];
  self.BoL_min_green_rate_below_alone = Config.vision.ball.BoL_min_green_rate_below_alone[cidx];
  self.BoL_min_green_rate_above = Config.vision.ball.BoL_min_green_rate_above[cidx];
  self.BoL_min_green_rate_above_alone = Config.vision.ball.BoL_min_green_rate_above_alone[cidx];
  self.BoL_max_y_axis_value = Config.vision.ball.BoL_max_y_axis_value[cidx];
  self.BoL_min_y_axis_value = Config.vision.ball.BoL_min_y_axis_value[cidx];
  self.BoL_max_x_axis_value = Config.vision.ball.BoL_max_x_axis_value[cidx];
  self.BoL_min_x_axis_value = Config.vision.ball.BoL_min_x_axis_value[cidx];
  self.BoL_min_height = Config.vision.ball.BoL_min_height[cidx];
  self.BoL_max_height = Config.vision.ball.BoL_max_height[cidx];
  self.BoL_max_fill_rate_undefined = Config.vision.ball.BoL_max_fill_rate_undefined[cidx];
  self.BoL_max_centroid_dist = Config.vision.ball.BoL_max_centroid_dist[cidx];
  self.max_centroid_dist = Config.vision.ball.max_centroid_dist[cidx];
  self.th_max_fill_rate_undefined = Config.vision.ball.th_max_fill_rate_undefined[cidx];

  return self
end

return detectBall
