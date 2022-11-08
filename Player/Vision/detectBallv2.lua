require('Config');      -- For Ball and Goal Size require('ImageProc');
require('HeadTransform');       -- For Projection
require('Body');
require('vcm');
require('mcm');
require('math');

bottom_boudary_check = Config.vision.ball.bottom_boudary_check or 0 -- 0 as of 07-13-2017
ball_check_for_ground = Config.vision.ball.check_for_ground; -- 1 as of 07-13-2017
check_for_field = Config.vision.ball.check_for_field or 0; -- 0 as of 07-13-2017
field_margin = Config.vision.ball.field_margin or 0; -- 0 as of 07-13-2017


local function check_boundary(self, headAngle, p_vision, check_passed)
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

  if math.abs(headAngle[1])>math.pi/3 then
    if (self.propsA.centroid[1]<leftboundary or self.propsA.centroid[2]>rightboundary)
      and self.propsA.centroid[2]>bottomboundary then
      check_passed = false;
    end
  end

  return check_passed
end

local function check_blob_properties(self, top_camera, fill_rate, aspect_ratio, black_rate, props_black, check_passed)
	if top_camera == false then
    th_min_fill_rate = self.th_min_fill_rate_btm;
    th_min_black_rate = self.th_min_black_rate_btm;
  elseif top_camera == true then
    th_min_fill_rate = self.th_min_fill_rate_top;
    th_min_black_rate = self.th_min_black_rate_top;
  end

  if fill_rate < th_min_fill_rate then --Fill rate check
    check_passed = false;
  elseif self.propsA.boundingBox[4] < HeadTransform.get_horizonA() then
     check_passed = false;
  elseif aspect_ratio > self.th_max_aspect_ratio then -- aspect ratio check
     check_passed = false;
  elseif aspect_ratio < self.th_min_aspect_ratio then
     check_passed = false;
  elseif black_rate < th_min_black_rate then -- black ratio check
    check_passed = false;
  elseif black_rate > self.th_max_black_rate then
    check_passed = false;
  elseif props_black.area < self.th_min_black_area then -- min black area check
    check_passed = false;
  end

  return check_passed
end


local function check_ball_height(self, v, top_camera, check_passed)
  local min_height, max_height;
  if top_camera == false then
    min_height = self.min_height_btm
    max_height = self.max_height_btm
  elseif top_camera == true then
    min_height = self.min_height_top
    max_height = self.max_height_top
  end

  if v[3] < min_height or v[3] > max_height then
    check_passed = false
  end

  return check_passed
end


local function check_horizon(self, v, v_inf, check_passed)
  -- Distance - height check
  exp_height = 0.0764*math.sqrt(v[1]*v[1] + v[2]*v[2])
  height_diff = math.abs(v[3] - exp_height)
  local height_err = 0.20
  ball_dist_inf = math.sqrt(v_inf[1]*v_inf[1] + v_inf[2]*v_inf[2])
  height_th_inf = self.th_height_max + ball_dist_inf * math.tan(10*math.pi/180)
  if v_inf[3] > height_th_inf then
     check_passed = false;
  end

  return check_passed
end

local function check_global_ball_position(self, check_passed)
  local pose = wcm.get_pose();
  local posexya=vector.new( {pose.x, pose.y, pose.a} );
  local ballGlobal=util.pose_global({v[1],v[2],0},posexya);
  if ballGlobal[1]>Config.world.xMax * self.fieldsize_factor or
     ballGlobal[1]<-Config.world.xMax * self.fieldsize_factor or
     ballGlobal[2]>Config.world.yMax * self.fieldsize_factor or
     ballGlobal[2]<-Config.world.yMax * self.fieldsize_factor then
    if (v[1]*v[1] + v[2]*v[2] > self.max_distance*self.max_distance) then
      check_passed = false;
    end
  end

  return check_passed
end

local function check_ball_height_top_cam(self, v, check_passed)
  local ball_dist = math.sqrt(v[1]*v[1] + v[2]*v[2])
  local height_th = self.th_height_max + ball_dist * math.tan(8*math.pi/180)
  if check_passed and v[3] > 0.3 then
    check_passed = false
  end
  
  if check_passed and v[3] > height_th then
    check_passed = false;
  end

  return check_passed
end

local function check_green_everywhere(self, p_vision, top_camera, ballCentroid, dArea, check_passed)
  local vmargin=p_vision.labelA.n-ballCentroid[2];
  local hmargin=p_vision.labelA.m-ballCentroid[1];
  
  if ((ballCentroid[1] > dArea and top_camera) or (ballCentroid[1] > dArea / 2 and not top_camera)) then
    local fieldBBox_left = {}
    fieldBBox_left[1] = ballCentroid[1] - .5*dArea + self.th_ground_boundingbox[1];
    fieldBBox_left[2] = ballCentroid[1] - .5*dArea;
    fieldBBox_left[3] = ballCentroid[2] - .5*dArea;
    fieldBBox_left[4]= ballCentroid[2] + .5*dArea;
    local left_area = vcm.bboxArea(fieldBBox_left);

    local fieldBBoxStats_left = ImageProc.color_stats(p_vision.labelA.data, p_vision.labelA.m, p_vision.labelA.n, Config.color.field, fieldBBox_left);
    
    if (fieldBBoxStats_left.area/left_area < self.th_min_green1) then
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
    local right_area = vcm.bboxArea(fieldBBox_right);
    local fieldBBoxStats_right = ImageProc.color_stats(p_vision.labelA.data, p_vision.labelA.m, p_vision.labelA.n, Config.color.field, fieldBBox_right);
    
    if (fieldBBoxStats_right.area/right_area < self.th_min_green1) then
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
    local top_green_area = vcm.bboxArea(fieldBBox_top);

    local fieldBBoxStats_top = ImageProc.color_stats(p_vision.labelA.data, p_vision.labelA.m, p_vision.labelA.n, Config.color.field, fieldBBox_top);
    if (fieldBBoxStats_top.area/top_green_area < self.th_min_green1) then
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

    local btm_green_area = vcm.bboxArea(fieldBBox_btm);

    local fieldBBoxStats_btm = ImageProc.color_stats(p_vision.labelA.data, p_vision.labelA.m, p_vision.labelA.n, Config.color.field, fieldBBox_btm);
    if (fieldBBoxStats_btm.area/btm_green_area < self.th_min_green2) then
      -- bottom may cast some shadow
      check_passed = false;
    end
  end

	if ((ballCentroid[2] > dArea and top_camera) or (ballCentroid[2] > dArea / 2 and not top_camera)) and check_passed then
		--print('using this')
    local fieldBBox_top = {}
    fieldBBox_top[1] = math.floor((ballCentroid[1] - .5*dArea)/self.scaleB);
    fieldBBox_top[2] = math.floor((ballCentroid[1] + .5*dArea)/self.scaleB);
    fieldBBox_top[3] = math.floor((ballCentroid[2] - .5*dArea + self.th_ground_boundingbox[3])/self.scaleB);
    fieldBBox_top[4] = math.floor((ballCentroid[2] - .5*dArea)/self.scaleB);
    local top_green_area = vcm.bboxArea(fieldBBox_top)/self.scaleB;

    local fieldBBoxStats_top = ImageProc.color_stats(p_vision.labelB.data, p_vision.labelB.m, p_vision.labelB.n, Config.color.field, fieldBBox_top);
    if (fieldBBoxStats_top.area/top_green_area < self.th_min_green1) then
      check_passed = false;
    end
  else
    check_passed = false;
  end

  return check_passed
end

local function check_undefined_fill_rate(self, p_vision, bboxA, props_black, check_passed)
  local props_green = ImageProc.color_stats(p_vision.labelA.data,p_vision.labelA.m, p_vision.labelA.n, self.field, bboxA);
  local fill_rate_undefined = 1 - (self.propsA.area + props_black.area + props_green.area) / vcm.bboxArea(self.propsA.boundingBox);
  if fill_rate_undefined > self.th_max_fill_rate_undefined then
    check_passed = false;
  end

  return check_passed
end

local function check_black_centroid_dist(self, ballCentroid, props_black, check_passed)
  local x_centroid_dist = (ballCentroid[1] - props_black.centroid[1])
  local y_centroid_dist = (ballCentroid[2] - props_black.centroid[2])
  local centroid_dist = math.sqrt(x_centroid_dist*x_centroid_dist + y_centroid_dist*y_centroid_dist)
  if centroid_dist > self.max_centroid_dist then
     check_passed = false;
  end

  return check_passed
end

local function check_bw_centroid_dist(self, props_white, props_black, check_passed)
  local x_centroid_dist = (props_white.centroid[1] - props_black.centroid[1])
  local y_centroid_dist = (props_white.centroid[2] - props_black.centroid[2])
  local centroid_dist = math.sqrt(x_centroid_dist*x_centroid_dist + y_centroid_dist*y_centroid_dist)
  if centroid_dist > self.RP_max_bw_centroid_dist then
     check_passed = false;
  end

  return check_passed
end


local function getBallDiameterAtA(self, x, y, ballDiameter)
	local v_obs = HeadTransform.coordinatesA({x, y}, 1);
	local v_actual = HeadTransform.projectGround(v_obs, ballDiameter/2);
	local d = self.diameter*((v_obs[3] - HeadTransform.getCameraOffset()[3])/(v_actual[3] - HeadTransform.getCameraOffset()[3]));

	return d
end

local function getBallDiameterAtB(self, x, y, ballDiameter)
	local v_obs = HeadTransform.coordinatesB({x, y}, 1);
	local v_actual = HeadTransform.projectGround(v_obs, ballDiameter/2);
	local d = self.diameter*((v_obs[3] - HeadTransform.getCameraOffset()[3])/(v_actual[3] - HeadTransform.getCameraOffset()[3]));

	return d
end

local function find_row_col(input)
  --input is binary tensor and output is (row, col) indices of 1's
  local t = torch.range(1, input:nElement())[torch.eq(input, 1)]
  local row = torch.floor(t/input:size()[2])+1
  local col = t - (row-1)*input:size()[2]
  
  return row, col
end

local function check_white_blobs_in_bboxA(self, p_vision, bboxA, check_passed)

	--local test1 = torch.ByteTensor(10,10):fill(1);
	--test1[{{2,4},{2,4}}] = 20;
	--print(test1)
	--local test2 = ImageProc.connected_regions(cutil.torch_to_userdata(test1), 10, 10, 1);
	--print(test2[1].boundingBox[1], test2[1].boundingBox[3], test2[1].boundingBox[2], test2[1].boundingBox[4])


	--print('original bboxA:  '..bboxA[3], bboxA[4], bboxA[1], bboxA[2])
	local subImg = p_vision.labelA.dataDP:sub(math.max(1,bboxA[3]), math.min(bboxA[4], p_vision.labelA.n), math.max(1,bboxA[1]), math.min(bboxA[2], p_vision.labelA.m)):clone()
	---print(subImg:size())
	----print(torch.sum(torch.eq(subImg,1)))	
	--print(subImg)

	--print(p_vision.labelA.dataDP:size()) -- 120, 160
	--print(p_vision.labelA.m, p_vision.labelA.n) --160, 120
	--print(subImg:size()[2], subImg:size()[1])

	local white_blobs = ImageProc.connected_regions(cutil.torch_to_userdata(subImg), subImg:size()[2], subImg:size()[1], Config.color.white);
	if white_blobs then
		local max_area_blob = white_blobs[1];
		local aspect_ratio = (max_area_blob.boundingBox[2] - max_area_blob.boundingBox[1] + 1) / (max_area_blob.boundingBox[4] - max_area_blob.boundingBox[3] + 1);
		
		if aspect_ratio < self.RP_min_aspect_ratio or aspect_ratio > self.RP_max_aspect_ratio then
			p_vision:add_debug_message(string.format("white aspect ratio: %.2f fail (%.2f - %.2f) \n", aspect_ratio, self.RP_min_aspect_ratio, self.RP_max_aspect_ratio))
			check_passed = false;
		end
		--for i=1,#white_blobs do
		--	print(white_blobs[i].boundingBox[1], white_blobs[i].boundingBox[2], white_blobs[i].boundingBox[3], white_blobs[i].boundingBox[4])
		--	print('area:  '..white_blobs[i].area)
		--end
		return check_passed
	end
	--print(white_blobs[i].centroid[1], white_blobs[i].centroid[2])
	--print(white_blobs[i].area)

end


local function check_black_blobs_in_bboxA(self, p_vision, bboxA, check_passed)

	--print('original bboxA:  '..bboxA[3], bboxA[4], bboxA[1], bboxA[2])
	local subImg = p_vision.labelA.dataDP:sub(math.max(1,bboxA[3]), math.min(bboxA[4], p_vision.labelA.n), math.max(1,bboxA[1]), math.min(bboxA[2], p_vision.labelA.m)):clone()
	
	local black_blobs = ImageProc.connected_regions(cutil.torch_to_userdata(subImg), subImg:size()[2], subImg:size()[1], Config.color.black);
	if black_blobs then
		local max_area_blob = black_blobs[1];

		--print(max_area_blob.boundingBox[1], max_area_blob.boundingBox[2], max_area_blob.boundingBox[3], max_area_blob.boundingBox[4])

		local aspect_ratio = (max_area_blob.boundingBox[2] - max_area_blob.boundingBox[1] + 1) / (max_area_blob.boundingBox[4] - max_area_blob.boundingBox[3] + 1);
		
		if aspect_ratio > 1.3 or aspect_ratio < 1/1.3 then
			p_vision:add_debug_message(string.format("black aspect ratio: %.2f fail (%.2f - %.2f) \n", aspect_ratio, 1/1.2, 1.2))
			check_passed = false;
		end
		
		local black_blob_area_ratio = math.log(vcm.bboxArea(max_area_blob.boundingBox)) / math.log(vcm.bboxArea(bboxA));
		if black_blob_area_ratio < 0.5 or black_blob_area_ratio > 0.75 then
			p_vision:add_debug_message(string.format("black area: %.2f fail (%.2f - %.2f) \n", black_blob_area_ratio, 0, 0.4))
			check_passed = false;
		end

		local black_fill = ImageProc.color_stats(p_vision.labelA.data, p_vision.labelA.m, p_vision.labelA.n, Config.color.orange, bboxA);
		local black_fill_rate = black_fill.area / vcm.bboxArea(max_area_blob.boundingBox);

		if black_fill_rate < 1.5 then
			p_vision:add_debug_message(string.format("black fill rate: %.2f fail (%.2f) \n", black_fill_rate, 1.5))
			check_passed = false;
		end

		--for i=1,#white_blobs do
		--	print(white_blobs[i].boundingBox[1], white_blobs[i].boundingBox[2], white_blobs[i].boundingBox[3], white_blobs[i].boundingBox[4])
		--	print('area:  '..white_blobs[i].area)
		--end
		return check_passed
	end
	--print(white_blobs[i].centroid[1], white_blobs[i].centroid[2])
	--print(white_blobs[i].area)

end

local function checkForBall_RP(self, p_vision, bboxA, cb_intImg_t, y_intImg_t, useScaleB)
	local cidx = p_vision.camera_index;    

	p_vision:add_debug_message(string.format("bboxA: (%d, %d), (%d, %d)\n", bboxA[1], bboxA[3], bboxA[2], bboxA[4]));


	-- for green check
	bboxA_around = {};
	bboxA_around[1] = math.max(0, bboxA[1]-15);
	bboxA_around[2] = math.min(p_vision.labelA.m, bboxA[2]+15);
	bboxA_around[3] = math.max(0, bboxA[3]-15);
	bboxA_around[4] = math.min(p_vision.labelA.n, bboxA[4]+15);

	bboxA_above = {};
	bboxA_above[1] = bboxA[1];
	bboxA_above[2] = bboxA[2];
	bboxA_above[3] = math.max(0, bboxA[3] - math.floor(math.abs(bboxA[2]-bboxA[1])/2)-5  );
	bboxA_above[4] = bboxA[3]-5;
	
	bboxA_left = {};
	bboxA_left[1] = math.max(0, bboxA[1] - math.floor(math.abs(bboxA[2]-bboxA[1])/2)  );
	bboxA_left[2] = bboxA[1];
	bboxA_left[3] = bboxA[3];
	bboxA_left[4] = bboxA[4];

	bboxA_right = {};
	bboxA_right[1] = bboxA[2];
	bboxA_right[2] = math.min(p_vision.labelA.m, bboxA[2] + math.floor(math.abs(bboxA[2]-bboxA[1])/2)  );
	bboxA_right[3] = bboxA[3];
	bboxA_right[4] = bboxA[4];

	--bboxA_below = {};
	--bboxA_below[1] = bboxA[1];
	--bboxA_below[2] = bboxA[2];
	--bboxA_below[3] = math.min(p_vision.labelA.n, bboxA[3]+15);
	--bboxA_below[4] = math.min(p_vision.labelA.n, bboxA[4]+15);

	local green_around = ImageProc.color_stats(p_vision.labelA.data, p_vision.labelA.m, p_vision.labelA.n, Config.color.field, bboxA_around);
	local green_rate_around = green_around.area / (vcm.bboxArea(bboxA_around)-vcm.bboxArea(bboxA));
	p_vision:add_debug_message(string.format("Green around rate: %.2f \n", green_rate_around, self.RP_min_green_around_rate))

	if green_rate_around < self.RP_min_green_around_rate then
		--p_vision:add_debug_message(string.format("Green around rate: %.2f fail (> %.2f) \n", green_rate_around, self.RP_min_green_around_rate))
		return false;
	end

	local green_above = ImageProc.color_stats(p_vision.labelA.data, p_vision.labelA.m, p_vision.labelA.n, Config.color.field, bboxA_above);
	local green_above_rate = green_above.area / ((bboxA_above[2]-bboxA_above[1]+1)*(bboxA_above[4]-bboxA_above[3]+1))
	if cidx == 1 and green_above_rate < self.RP_min_green_above_rate then
			p_vision:add_debug_message(string.format("Green above rate: %.2f fail (> %.2f) \n", green_above_rate, self.RP_min_green_above_rate))
			--print(green_above_rate)
			return false;
	end

	local green_left = ImageProc.color_stats(p_vision.labelA.data, p_vision.labelA.m, p_vision.labelA.n, Config.color.field, bboxA_left);
	local green_left_rate = green_left.area / ((bboxA_left[2]-bboxA_left[1]+1)*(bboxA_left[4]-bboxA_left[3]+1))
	--print(green_left_rate)
	if bboxA_left[2] ~= bboxA_left[1] and green_left_rate < self.RP_min_green_left_rate then
		p_vision:add_debug_message(string.format("Green left rate: %.2f fail (> %.2f) \n", green_left_rate, self.RP_min_green_left_rate))
		return false;
	end

	local green_right = ImageProc.color_stats(p_vision.labelA.data, p_vision.labelA.m, p_vision.labelA.n, Config.color.field, bboxA_right);
	local green_right_rate = green_right.area / ((bboxA_right[2]-bboxA_right[1]+1)*(bboxA_right[4]-bboxA_right[3]+1))
	--print(green_right_rate)
	if bboxA_right[2] ~= bboxA_right[1] and green_right_rate < self.RP_min_green_right_rate then
		p_vision:add_debug_message(string.format("Green right rate: %.2f fail (> %.2f) \n", green_right_rate, self.RP_min_green_right_rate))
		return false;
	end



  local props_white = ImageProc.color_stats(p_vision.labelA.data, p_vision.labelA.m, p_vision.labelA.n, Config.color.white, bboxA);
  local props_black = ImageProc.color_stats(p_vision.labelA.data, p_vision.labelA.m, p_vision.labelA.n, Config.color.orange, bboxA);

  if props_white.area == 0 or props_black.area == 0 then
		--p_vision:add_debug_message(string.format("props_white.area: $d", props_white.area))
		--p_vision:add_debug_message(string.format("props_black.area: $d", props_black.area))
		return false
  end

  local pitchThreshold = 20;
  local middleYaw = 0;
  local errorYaw = 25;
  local footRowIdx = 100;
  local headAngle = Body.get_head_position(); --{yaw, pitch}
	headAngle[1] = headAngle[1]/math.pi*180;
	headAngle[2] = headAngle[2]/math.pi*180;
	--print(headAngle[2] > pitchThreshold, headAngle[1] < headAngle[1] < middleYaw+errorYaw, 
	--				headAngle[1] > middleYaw-errorYaw)
	if ( (cidx == 2) and (headAngle[2] > pitchThreshold) and
       (headAngle[1] < (middleYaw+errorYaw)) and (headAngle[1] > (middleYaw-errorYaw)) ) then   
    if self.bboxCenterRow > (120-(headAngle[2]-20)*4) then --120 for pitch 20, 100 for pitch 25
      p_vision:add_debug_message(string.format("too close to foot \n"))
      return false;
    end
  end

	local pitchThreshold = 20;
	local yaw_min1 = 25;
	local yaw_max1 = 75;
	local yaw_min2 = -75;
	local yaw_max2 = -25;
	
	if ( (cidx == 2) and (headAngle[2] > pitchThreshold) and
			 (headAngle[1] < yaw_max1) and (headAngle[1] > yaw_min1) ) then
		if self.bboxCenterRow > 90 then
			p_vision:add_debug_message(string.format("too close to left shoulder \n"));
			return false;
		end
	end

	if ( (cidx == 2) and (headAngle[2] > pitchThreshold) and
			 (headAngle[1] < yaw_max2) and (headAngle[1] > yaw_min2) ) then
		if self.bboxCenterRow > 90 then
			p_vision:add_debug_message(string.format("too close to right shoulder \n"));
			return false;
		end
	end

  local fill_rate = (props_white.area + props_black.area) / vcm.bboxArea(bboxA);
	local white_rate = (props_white.area) / vcm.bboxArea(bboxA);
  local black_rate =  props_black.area / props_white.area;

  if fill_rate < self.RP_min_fill_rate or fill_rate > self.RP_max_fill_rate then
    p_vision:add_debug_message(string.format("RP Fill rate: %.2f fail (%.2f - %.2f)\n", fill_rate, self.RP_min_fill_rate, self.RP_max_fill_rate));
    return false
  end
	
	if white_rate < self.RP_min_white_rate or white_rate > self.RP_max_white_rate then
		p_vision:add_debug_message(string.format("RP White rate: %.2f fail (%.2f - %.2f) \n", white_rate, self.RP_min_white_rate, self.RP_max_white_rate))
		return false
	end

  if black_rate < self.RP_min_black_rate or black_rate > self.RP_max_black_rate then
    p_vision:add_debug_message(string.format("RP Black rate: %.2f fail (%.2f - %.2f)\n", black_rate, self.RP_min_black_rate, self.RP_max_black_rate));
    return false
  end

	local temp_check_passed = true;
	local temp_check_passed = check_bw_centroid_dist(self, props_white, props_black, temp_check_passed)
	if cidx == 2 and temp_check_passed == false then
		p_vision:add_debug_message(string.format("bw dist too big \n"))
		return false;
	end

	if cidx == 2 then 
		temp_check_passed = check_white_blobs_in_bboxA(self, p_vision, bboxA, temp_check_passed);
		temp_check_passed = check_black_blobs_in_bboxA(self, p_vision, bboxA, temp_check_passed);
	end
	if cidx == 2 and temp_check_passed == false then
		return false;
	end

  self.propsA = {};
	self.propsA.centroid = {self.bboxCenterCol, self.bboxCenterRow}; --{bboxA['col'], bboxA['row']}; -- props_centroid
  self.propsA.axisMajor = bboxA[2]-bboxA[1]+1; --getBallDiameterAtA(self, self.propsA.centroid[1], self.propsA.centroid[2]); -- props_ballDiameter
	--print('getBallDiameterAtA  '..getBallDiameterAtA(self, self.propsA.centroid[1], self.propsA.centroid[2]))
	--print('self.propsA.axisMajor  '..self.propsA.axisMajor)
  self.propsA.axisMinor = 0;
	
  v = HeadTransform.projectGround(HeadTransform.coordinatesA(self.propsA.centroid, 1), self.diameter/2); -- props_v = HeadTransform.projectGround(HeadTransform.coordinatesA(props_centroid, 1), self.diameter/2);

  v_inf = HeadTransform.coordinatesA(self.propsA.centroid, 0.1);

	--print(green_above_rate)

  return true
end


---Detects a ball of a given color.
--@param color The color to use for detection, represented by an int
--@return Table containing whether a ball was detected
--If a ball is detected, also contains additional stats about the ball
local update = function(self, color, line_info, p_vision)

	-- stuff from before 07-10-2017
	local top_camera = false
  if p_vision.camera_index==1 then top_camera=true end
  local colorCount = p_vision.colorCount;
  headAngle = Body.get_head_position();
  self.detect = 0;
  self.on_line = 0;
	self.fromRP = 0;
	self.new_bbox = 0;
  self.color_count = colorCount[color];

  local ballPropsB = ImageProc.connected_regions(p_vision.labelB.data, p_vision.labelB.m, p_vision.labelB.n, Config.color.white);
  if (not ballPropsB or #ballPropsB == 0) then return end -- no blob detected

  local check_passed  -- Check all blobs until hit a ball that no longer passes area check

  if top_camera then
    p_vision:add_debug_message('===Top Ball check===\n')
  else
    p_vision:add_debug_message('===Bottom Ball check===\n');
  end

  for i=1,#ballPropsB do
    check_passed = true;
    if check_passed then
      self.propsB = ballPropsB[i];
      local bboxA = vcm.bboxB2A(ballPropsB[i].boundingBox, p_vision.scaleB);
      self.bboxA = bboxA

      self.propsA = ImageProc.color_stats(p_vision.labelA.data, p_vision.labelA.m, p_vision.labelA.n, Config.color.white, bboxA);

      if top_camera == false and bottom_boudary_check == 1 then
          check_passed = check_boundary(self, headAngle, p_vision, check_passed) -- for false positives detected on jersey on bottom cam
      end

      -- FILTER OUR THE WRONG BALL BASED ON DIFFERENT CHECKS
      -- Defining variables
      local aspect_ratio = self.propsA.axisMajor / self.propsA.axisMinor
      if (self.propsA.axisMinor == 0) then aspect_ratio = self.propsA.axisMajor / 0.00001 end
      local props_black = ImageProc.color_stats(p_vision.labelA.data, p_vision.labelA.m, p_vision.labelA.n, Config.color.orange, bboxA);
      local props_cyan = ImageProc.color_stats(p_vision.labelA.data, p_vision.labelA.m, p_vision.labelA.n, Config.color.cyan, bboxA); -- not used
      local black_rate =  props_black.area / self.propsA.area
      local fill_rate = (self.propsA.area + props_black.area) / vcm.bboxArea(self.propsA.boundingBox)

      
      if self.propsA.area > self.th_max_color2 then  --Max color check
        check_passed = false;
      elseif self.propsA.area < self.th_min_color2 then --Min color check
        check_passed = false;
      end

      if check_passed then
        check_passed = check_blob_properties(self, top_camera, fill_rate, aspect_ratio, black_rate, props_black, check_passed);
      end

      if check_passed then
        --Now we have somewhat solid blob somewhere. Get the position of it
        local dArea = math.sqrt((4/math.pi)* self.propsA.area);-- diameter of the area
        local ballCentroid = self.propsA.centroid;-- Find the centroid of the ball
        local scale = math.max(dArea/self.diameter, self.propsA.axisMajor/self.diameter)
        v = HeadTransform.coordinatesA(ballCentroid, scale) -- Coordinates of ball
        v_inf = HeadTransform.coordinatesA(ballCentroid,0.1) --far-projected coordinate of the ball

        if check_passed then
          check_passed = check_ball_height(self, v, top_camera, check_passed);
        end

        if top_camera and check_passed then
          check_passed = check_horizon(self, v, v_inf, check_passed);
          check_passed = check_global_ball_position(self, check_passed);
          check_passed = check_ball_height_top_cam(self, v, check_passed)
        end

        if check_passed then --Pink check (ball in jersey)
          if ball_check_for_ground>0  then  -- ground check
            -- is ball cut off at the bottom of the image?
            check_passed = check_green_everywhere(self, p_vision, top_camera, ballCentroid, dArea, check_passed);
          end
          
          check_passed = check_undefined_fill_rate(self, p_vision, bboxA, props_black, check_passed);
        end

        if check_passed then -- check for the centroid of the black area and check against centroid of white area
          check_passed = check_black_centroid_dist(self, ballCentroid, props_black, check_passed);
        end

      end
    end
    if check_passed then break end
  end --End propsB loop



	---------------------------------------------------------------------------------------
	-------------------------------- START REGION PROPOSAL --------------------------------
	---------------------------------------------------------------------------------------

  if not check_passed then

  	local useScaleB = true;
		local debug_cb = false;

  	local cidx = p_vision.camera_index;

  	local ballDiameter
  	if cidx == 1 then
  		ballDiameter = self.diameter;
  	else
  		ballDiameter = 0.115;
  	end
  	local br1, br2, br_slope;
  	
  	if useScaleB then
  		br1 = getBallDiameterAtB(self, p_vision.labelB.n/2, 1, ballDiameter)/2;
  		br2 = getBallDiameterAtB(self, p_vision.labelB.n/2, p_vision.labelB.m, ballDiameter)/2;
  		br_slope = (br2-br1)/p_vision.labelB.m;
  	else
  		br1 = getBallDiameterAtA(self, p_vision.labelA.n/2, 1, ballDiameter)/2; --min
  		br2 = getBallDiameterAtA(self, p_vision.labelA.n/2, p_vision.labelA.m, ballDiameter)/2; --max
  		br_slope = (br2-br1)/p_vision.labelA.m;
  	end

  	local min_ball_radius = 4; -- in pixels
  	local widthLocalMaxFilter = 5; --in pixels
  	local topMostRowAddOn = 10;

  	local localMaxThreshold, widthHighContrast
  	if cidx == 1 then
  		localMaxThreshold = 6 --17
  		widthHighContrast = 15
  	elseif cidx == 2 then
  		localMaxThreshold = 6 --20
  		widthHighContrast = 13
  	end
  	
  	if useScaleB then
  		min_ball_radius = math.floor(min_ball_radius/2);
  		topMostRowAddOn = math.floor(topMostRowAddOn/2);
  		widthHighContrast = math.floor(widthHighContrast/2);
  	end
  	--interpolate for every row pixels
  	local interpl_t
  	if useScaleB then
  		interpl_t = torch.range(1, p_vision.labelB.m):float();
  	else
  		interpl_t = torch.range(1, p_vision.labelA.m):float();
  	end
  	if cidx == 1 then
  		interpl_t = torch.mul(interpl_t, br_slope) + br1
  		interpl_t = interpl_t:floor();
  		interpl_t[torch.lt(interpl_t, min_ball_radius)] = 0; -- interpolated ball radii at different row pixels
  	else
  		interpl_t = torch.mul(interpl_t, br_slope) + br1
  		local temp = interpl_t:clone():floor();
  		local ceilIdx = torch.ge(torch.abs(interpl_t-temp), 0.5)
  		temp[ceilIdx] = interpl_t[ceilIdx]:clone():ceil()
  		interpl_t = temp:clone()
  	end

  	--print(interpl_t)

  	-- get y and cb channels and store in tensors
  	local yuyvImg = vcm['get_image'..cidx..'_yuyv']();
  	local y_raw_t
  	if useScaleB then
  		y_raw_t = ImageProc.yuyv_to_ycbcr_scaleB(yuyvImg, 1)
  	else
  		y_raw_t = ImageProc.yuyv_to_ycbcr(yuyvImg, 1)
  	end
  	y_t = y_raw_t:float();
  	y_t = (y_t - 40)/4;
  	y_t[torch.lt(y_t, 0)] = 0;

  	local cb_raw_t
  	if useScaleB then
  		cb_raw_t = ImageProc.yuyv_to_ycbcr_scaleB(yuyvImg, 2)
  	else
  		cb_raw_t = ImageProc.yuyv_to_ycbcr(yuyvImg,2)
  	end
  	cb_t = cb_raw_t:float();
  	cb_t = cb_t-100;
  	cb_t[torch.lt(cb_t,0)] = 0;

		if debug_cb == true then
			self.cb.data = cutil.torch_to_userdata(ImageProc.yuyv_to_ycbcr(yuyvImg,2)); -- just to show what it looks like in labelA
  		self.cbScaleB.data = cutil.torch_to_userdata(cb_t:byte());
		end

  	-- calculate integral image and store in "int_img" tensor
  	local cb_intImg_t = torch.FloatTensor(cb_t:size());
  	ImageProc.integral_image(cb_intImg_t, cb_t);
  	
  	local y_intImg_t = torch.FloatTensor(y_t:size());
  	ImageProc.integral_image(y_intImg_t, y_t);
  	
  	-- zero out areas with low stdev in y channel values (using grids)
  	local mask_t = torch.ByteTensor(cb_t:size()):fill(0);
  	ImageProc.high_contrast_parts(mask_t, y_t, y_intImg_t, interpl_t, min_ball_radius, widthHighContrast, cidx);


  	-- calculate diffImg and localMaxIdx
  	local diffImg_t = torch.FloatTensor(cb_t:size()):fill(0);
  	ImageProc.diff_img(diffImg_t, cb_intImg_t, mask_t, interpl_t, min_ball_radius, cidx);

  	local topMostRow = ImageProc.top_most_row(diffImg_t);

  	local localMaxIdx = ImageProc.local_max(diffImg_t, widthLocalMaxFilter, localMaxThreshold, math.min(topMostRow+topMostRowAddOn, cb_t:size()[1]-1));

  	
  	self.n_bbox = torch.sum(localMaxIdx);
  	--print(self.n_bbox)
  	local row,col = find_row_col(localMaxIdx);
  	
  	self.bboxLeftTopX = {}
  	self.bboxLeftTopY = {}
  	self.bboxRightBottomX = {}
  	self.bboxRightBottomY = {}

  	local bboxLeftTopX = {}
  	local bboxRightBottomX = {}
  	local bboxLeftTopY = {}
  	local bboxRightBottomY = {}

  	for i=1,self.n_bbox do
  		if useScaleB then
  			bboxLeftTopX[i] = (col[i] - interpl_t[row[i]])*2;
  			bboxRightBottomX[i] = (col[i] + interpl_t[row[i]])*2;
  			bboxLeftTopY[i] = (row[i] - interpl_t[row[i]])*2;
  			bboxRightBottomY[i] = (row[i] + interpl_t[row[i]])*2;
  		else
  			bboxLeftTopX[i] = col[i]* - interpl_t[row[i]];
  			bboxRightBottomX[i] = col[i] + interpl_t[row[i]];
  			bboxLeftTopY[i] = row[i] - interpl_t[row[i]];
  			bboxRightBottomY[i] = row[i] + interpl_t[row[i]];
  		end	
  		self.bboxLeftTopX[i] = bboxLeftTopX[i];
  		self.bboxRightBottomX[i] = bboxRightBottomX[i];
  		self.bboxLeftTopY[i] = bboxLeftTopY[i];
  		self.bboxRightBottomY[i] = bboxRightBottomY[i];
  	end
  	
    ---------------------------------------------------------------------------------------
    --------------------------- END OF REGION PROPOSALS -----------------------------------
    ---------------------------------------------------------------------------------------

    local bboxA;

  	if self.n_bbox > 0 then
  		self.new_bbox = 1;
  		--print('new bounding boxes')
  	end

  	for i=1,self.n_bbox do
  		bboxA = {};
  		bboxA[1] = self.bboxLeftTopX[i];
  		bboxA[2] = self.bboxRightBottomX[i];
  		bboxA[3] = self.bboxLeftTopY[i];
  		bboxA[4] = self.bboxRightBottomY[i];
  		
  		if useScaleB then
  			self.bboxCenterRow = row[i]*2
  			self.bboxCenterCol = col[i]*2
  		else
  			self.bboxCenterRow = row[i]
  			self.bboxCenterCol = row[i]
  		end

  		check_passed = checkForBall_RP(self, p_vision, bboxA, cb_intImg_t, y_intImg_t, useScaleB);
  		
  		if check_passed then
  			self.fromRP = 1;
  			break
  		end
    end -- end of for loop for iterating through n_bbox
  end -- end of if statement for entire region proposal + checkForBall stage

  ----------------------------------------------------------------------------------------
  -------------------------------END OF DETECTION-----------------------------------------
  ----------------------------------------------------------------------------------------

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
	if vcm.get_camera_broadcast() > 0 then
		vcm['set_image'..cidx..'_cb'](self.cb.data);
		vcm['set_image'..cidx..'_cbScaleB'](self.cbScaleB.data);
	end
  vcm['set_ball'..cidx..'_detect'](self.detect);
	vcm['set_ball'..cidx..'_newBbox'](self.new_bbox);
	vcm['set_ball'..cidx..'_fromRP'](self.fromRP);
	if (self.new_bbox == 1) then
		vcm['set_ball'..cidx..'_bboxLeftTopX'](self.bboxLeftTopX);
		vcm['set_ball'..cidx..'_bboxRightBottomX'](self.bboxRightBottomX);
		vcm['set_ball'..cidx..'_bboxLeftTopY'](self.bboxLeftTopY);
		vcm['set_ball'..cidx..'_bboxRightBottomY'](self.bboxRightBottomY);
	end

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
	self.cb = {}
	self.cbScaleB = {}
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


  self.fromRP = 0;
  self.RP_min_fill_rate = Config.vision.ball.RP_min_fill_rate[cidx];
  self.RP_max_fill_rate = Config.vision.ball.RP_max_fill_rate[cidx];
  self.RP_min_white_rate = Config.vision.ball.RP_min_white_rate[cidx];
  self.RP_max_white_rate = Config.vision.ball.RP_max_white_rate[cidx];
  self.RP_min_black_rate = Config.vision.ball.RP_min_black_rate[cidx];
  self.RP_max_black_rate = Config.vision.ball.RP_max_black_rate[cidx];
  self.RP_min_green_around_rate = Config.vision.ball.RP_min_green_around_rate[cidx];
	self.RP_min_green_above_rate = Config.vision.ball.RP_min_green_above_rate[cidx];
	self.RP_min_green_left_rate = Config.vision.ball.RP_min_green_left_rate[cidx];
	self.RP_min_green_right_rate = Config.vision.ball.RP_min_green_right_rate[cidx];
  self.RP_max_bw_centroid_dist = Config.vision.ball.RP_max_bw_centroid_dist[cidx];
	self.RP_min_aspect_ratio = Config.vision.ball.RP_min_aspect_ratio;
  self.RP_max_aspect_ratio = Config.vision.ball.RP_max_aspect_ratio;

	self.scaleB = Config.vision.scaleB[cidx];

  return self
end

return detectBall
