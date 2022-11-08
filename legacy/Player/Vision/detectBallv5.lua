require('Config');      -- For Ball and Goal Size require('ImageProc');
require('HeadTransform');       -- For Projection
require('Body');
require('vcm');
require('mcm');
require('math');
require('vector')

require('nn_forward');
require('File')

local function remove_foot(self, diffImg_t, headAngle, nrows)
  -- headAngle = {yaw, pitch}
  local pitchThreshold = 20;
  local middleYaw = 0;
  local errorYaw = 25;
  local bottomMostRow

  --print(headAngle[2] > pitchThreshold, headAngle[1] < headAngle[1] < middleYaw+errorYaw, 
  --        headAngle[1] > middleYaw-errorYaw)
  if ( (headAngle[1] > (middleYaw-errorYaw))  and
       (headAngle[1] < (middleYaw+errorYaw)) and 
       (headAngle[2] > pitchThreshold) ) then   
    bottomMostRow = 60-(headAngle[2]-20)*2 -- 60 for pitch 20, 50 for pitch 25
    diffImg_t[{{bottomMostRow, nrows},{}}] = 0
  end

  return diffImg_t
end

local function remove_shoulders(self, diffImg_t, headAngle, nrows)
  local pitchThreshold = 20;
  local yaw_min1 = 25;
  local yaw_max1 = 75;
  local yaw_min2 = -75;
  local yaw_max2 = -25;

  --print(headAngle[1], headAngle[2])
  
  if ( (headAngle[1] > yaw_min1) and
       (headAngle[1] < yaw_max1) and
       (headAngle[2] > pitchThreshold) ) then
    bottomMostRow = 45
    diffImg_t[{{bottomMostRow, nrows},{}}] = 0
  end

  if ( (headAngle[1] > yaw_min2) and
       (headAngle[1] < yaw_max2) and 
       (headAngle[2] > pitchThreshold) ) then
    bottomMostRow = 45
    diffImg_t[{{bottomMostRow, nrows},{}}] = 0
  end

  return diffImg_t
end

local function getBallDiameterAtA(self, x, y, ballDiameter)
	local v_obs = HeadTransform.coordinatesA({x, y}, 1);
	local v_actual = HeadTransform.projectGround(v_obs, ballDiameter/2);
	local d = ballDiameter*((v_obs[3] - HeadTransform.getCameraOffset()[3])/(v_actual[3] - HeadTransform.getCameraOffset()[3]));

	return d
end

local function getBallDiameterAtB(self, x, y, ballDiameter)
	local v_obs = HeadTransform.coordinatesB({x, y}, 1);
	local v_actual = HeadTransform.projectGround(v_obs, ballDiameter/2);
	local d = ballDiameter*((v_obs[3] - HeadTransform.getCameraOffset()[3])/(v_actual[3] - HeadTransform.getCameraOffset()[3]));

	return d
end

local function find_row_col(input)
  --input is binary tensor of size (nrow,ncol) and output is (row, col) indices of 1's
  local t = torch.range(1, input:nElement())[torch.eq(input, 1)]-1
  local ncol = input:size(2)
  local row = torch.floor(t/ncol)+1
  local col = t - (row-1)*ncol+1
  
  return row, col
end

local function get_top_n_localMax(local_MaxIdx, top_n, diffImg_t)
  local diffImg_t_copy = diffImg_t:clone()
  inverse_local_MaxIdx = torch.ByteTensor(local_MaxIdx:size()):fill(1):add(-local_MaxIdx) -- doing 1-local_MaxIdx.. operation not available in this version of torch
  diffImg_t_copy[inverse_local_MaxIdx] = 0 -- set any non-relevant value to 0
  local sorted, indices = torch.sort(diffImg_t_copy:view(1,-1))
  
  local mask = torch.ByteTensor(local_MaxIdx:size()):fill(0):view(1,-1)
  local indices_top = indices[{1, {-top_n, -1}}]
 
  mask:indexCopy(2, indices_top, torch.ByteTensor(1, top_n):fill(1))
  local new_local_MaxIdx = mask:view(local_MaxIdx:size())
  
  return new_local_MaxIdx
end

local function checkForBall_NN(self, y_raw_t_scaleA, bboxA)
  local bboxLeft = bboxA[1]
  local bboxRight = bboxA[2]
  local bboxTop = bboxA[3]
  local bboxBottom = bboxA[4]

  -- defining subimage
  local input
  if (bboxRight - bboxLeft) == (bboxBottom - bboxTop) then
    input = y_raw_t_scaleA[{{bboxTop, bboxBottom},{bboxLeft, bboxRight}}]
    input = input:reshape(1, input:size(1), input:size(2))
  else
    print('bbox not square')
    return false
  end

  -- image resize from (1 x nrow x ncol) to (1 x 20 x 20)
  local outputWidth = 20 -- don't change this. nn_forward is custom built to handle width of 20
  local input_resized = ImageProc.im_rescale_DP(input:float(), outputWidth)
  if (input_resized:std()~=0) then
    input_nn = (input_resized-input_resized:mean())/input_resized:std()
  else
    input_nn = (input_resized-input_resized:mean())
  end

  local output = nn_forward(input_nn, self.nn_weight_table)
  --local output = torch.LongTensor({0,1})

  output_log_softmax, pred_label = torch.max(output,1)

	--print('pred')
	--print(math.exp(output_log_softmax[1]))

  local nn_output_threshold = 0.96
  if pred_label[1] == 1 and math.exp(output_log_softmax[1])>nn_output_threshold then
    --print('ball')
    return true
  end

  return false
end

---Detects a ball with region proposal and CNN only.
--@return Table containing whether a ball was detected
--If a ball is detected, also contains additional stats about the ball
local update = function(self, dummy1, dummy2, p_vision)
  debug_cb = false;
  debug_RP = true;
  local check_passed = false
  self.detect = 0
  self.fromRP = 0
  self.new_bbox = 0

  self.bboxLeftTopX = {}
 	self.bboxLeftTopY = {}
 	self.bboxRightBottomX = {}
 	self.bboxRightBottomY = {}

	---------------------------------------------------------------------------------------
	-------------------------------- START REGION PROPOSAL --------------------------------
	---------------------------------------------------------------------------------------

----[=====[
  if not check_passed then

  	local useScaleB = true;

  	local cidx = p_vision.camera_index;

  	local ballDiameter
    --ballDiameter = self.diameter;
  	if cidx == 1 then --DP
  		ballDiameter = self.diameter;
  	else
  		ballDiameter = 0.105;
  	end

  	local br1, br2, br_slope;
  	if useScaleB then
  		br1 = getBallDiameterAtB(self, p_vision.labelB.m/2, 1, ballDiameter)/2;
  		br2 = getBallDiameterAtB(self, p_vision.labelB.m/2, p_vision.labelB.n, ballDiameter)/2;
  		br_slope = (br2-br1)/p_vision.labelB.n;
  	else
  		br1 = getBallDiameterAtA(self, p_vision.labelA.m/2, 1, ballDiameter)/2; --min
  		br2 = getBallDiameterAtA(self, p_vision.labelA.m/2, p_vision.labelA.n, ballDiameter)/2; --max
  		br_slope = (br2-br1)/p_vision.labelA.n;
  	end

  	local min_ball_radius = 3; -- in pixels
  	local widthLocalMaxFilter = 3; --in pixels
  	local topMostRowAddOn = 1;
  	
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
    y_ptr = cutil.torch_to_userdata(y_t)
    
    -- Ryan Walsh 2019, get Y (lumaniance) median and auto adjust the amount of contrast we are looking for
    -- The idea is that for dark images, there is less contrast compared to bright images
    -- Notice that this code is sensitive to image brightness and so you should experiment with hard values first if you don't know what you are doing
    
  --[[if cidx == 1 then -- Top camera

    n_rows_pct = .4 -- percentage of lower rows to use for calculation (idea: dumb non-genometric way to remove non field area)
    n_rows = math.floor(y_raw_t:size(1)*n_rows_pct)
    row_subset = torch.range(1, n_rows):add(1-n_rows_pct)
    y_sensor = y_raw_t[{row_subset, {}}]:float():std()
    
    widthHighContrast = 8

	print('ysensor', y_sensor)
  else -- Bottom camera
  	y_sensor  = y_raw_t:float():std()
  	print('ysensor', y_sensor)

	widthHighContrast = 12

  end
  --]]
 
  	
  	-- [[ RW 2019
  	local localMaxThreshold, widthHighContrast
  	if cidx == 1 then
  		localMaxThreshold = 2.5 --3
  		widthHighContrast = 7
  	elseif cidx == 2 then
  		localMaxThreshold = 5 --3
  		widthHighContrast = 12
  	end
  	-- ]]
  	
	--[[ DP
  	local localMaxThreshold, widthHighContrast
  	if cidx == 1 then
  		localMaxThreshold = 4.5 --3
  		widthHighContrast = 15
  	elseif cidx == 2 then
  		localMaxThreshold = 5 --3
  		widthHighContrast = 15
  	end
  	--]]
  	
  	if useScaleB then
  		min_ball_radius = math.floor(min_ball_radius/2);
  		topMostRowAddOn = math.floor(topMostRowAddOn/2);
  		widthHighContrast = math.floor(widthHighContrast/2);
  	end
  	
  	--interpolate for every row pixels
  	local interpl_t, max_row
  	if useScaleB then
      max_row = p_vision.labelB.n
  	else
      max_row = p_vision.labelA.n
  	end
  	
    image_row_t = torch.range(1, max_row):float();
    if cidx == 1 then
    	interpl_t = torch.mul(image_row_t, br_slope) + br1
    	interpl_t = interpl_t:floor();
    	interpl_t[torch.lt(interpl_t, min_ball_radius)] = 0; -- interpolated ball radii at different row pixels
      interpl_t[torch.gt(image_row_t + interpl_t, max_row)] = 0 -- prevents bbox from going below the img boudndary
      interpl_t[torch.lt(image_row_t - interpl_t, 0)] = 0 -- prevents bbox from going above the img boundary
    else
    	interpl_t = torch.mul(image_row_t, br_slope) + br1
    	local temp = interpl_t:clone():floor();
    	local ceilIdx = torch.ge(torch.abs(interpl_t-temp), 0.5)
    	temp[ceilIdx] = interpl_t[ceilIdx]:clone():ceil()
    	interpl_t = temp:clone()
      interpl_t[torch.gt(image_row_t + interpl_t, max_row)] = 0 -- prevents bbox from going below the img boudndary
      --print(image_row_t - interpl_t)
      interpl_t[torch.lt(image_row_t - interpl_t, 0)] = 0 -- prevents bbox from going above the img boudndary
      --print(interpl_t)
    end
    local interpl_ptr = cutil.torch_to_userdata(interpl_t)

  	local cb_raw_float_t
    if cidx == 1 then
      --ch2_ratio = 0.2
      ch2_ratio =  0.2
      --ch2_ratio = 0.5 --outdoor
    elseif cidx == 2 then
      --ch2_ratio = 0.3
      ch2_ratio =  0.2 -- Ryan 2019
      --ch2_ratio = 0.5 --outdoor
    end
    
  	if useScaleB then
  		cb_raw_float_t = ImageProc.yuyv_to_ycbcr_scaleB(yuyvImg, 2):float():mul(ch2_ratio)+ImageProc.yuyv_to_ycbcr_scaleB(yuyvImg, 3):float():mul(1-ch2_ratio)
  	else
      cb_raw_float_t = ImageProc.yuyv_to_ycbcr(yuyvImg, 2):float():mul(ch2_ratio)+ImageProc.yuyv_to_ycbcr_scaleB(yuyvImg, 3):float():mul(1-ch2_ratio)
  	end
  	--cb_t = cb_raw_float_t:clone();
    cb_t = cb_raw_float_t-100;
  	cb_t[torch.lt(cb_t,0)] = 0;
    local cb_ptr = cutil.torch_to_userdata(cb_t)

  	-- calculate integral image and store in "int_img" tensor
  	local cb_intImg_t = torch.FloatTensor(cb_t:size());
    local cb_intImg_ptr = cutil.torch_to_userdata(cb_intImg_t)

    local nrows = p_vision.labelB.n
    local ncols = p_vision.labelB.m
    local stride = p_vision.labelB.m

  	ImageProc.integral_image2(cb_intImg_ptr, cb_ptr, nrows, ncols, stride);

  	local y_intImg_t = torch.FloatTensor(y_t:size());
    local y_intImg_ptr = cutil.torch_to_userdata(y_intImg_t)
  	ImageProc.integral_image2(y_intImg_ptr, y_ptr, nrows, ncols, stride);

  	-- zero out areas with low stdev in y channel values (using grids)
  	local mask_t = torch.ByteTensor(cb_t:size()):fill(0);
    local mask_ptr = cutil.torch_to_userdata(mask_t)
  	ImageProc.high_contrast_parts2(mask_ptr, y_ptr, y_intImg_ptr, interpl_ptr, min_ball_radius, widthHighContrast, cidx, nrows, ncols);

  	-- calculate diffImg and localMaxIdx
  	local diffImg_t = torch.FloatTensor(cb_t:size()):fill(0);
    local diffImg_ptr = cutil.torch_to_userdata(diffImg_t)
  	ImageProc.diff_img2(diffImg_ptr, cb_intImg_ptr, mask_ptr, interpl_ptr, min_ball_radius, cidx, nrows, ncols);
    diffImg_t[diffImg_t:lt(0)] = 0
    --print(diffImg_t:max())
    
  	local topMostRow = ImageProc.top_most_row2(diffImg_ptr, nrows, ncols);

    --local localMaxIdx = torch.zeros(diffImg_t:size()):float()
    local cutoffRow
    if cidx == 1 then
      cutoffRow = math.min(topMostRow+topMostRowAddOn, cb_t:size()[1]-1)
    else
      cutoffRow = 0
    end

    local headAngle = Body.get_head_position(); --{yaw, pitch}
    headAngle[1] = headAngle[1]/math.pi*180;
    headAngle[2] = headAngle[2]/math.pi*180;

    if cidx == 2 then
      diffImg_t = remove_foot(self, diffImg_t, headAngle, nrows)
      test_t = remove_shoulders(self, cb_t, headAngle, nrows)
    end
  	
    local localMaxIdx = ImageProc.local_max2(diffImg_t, widthLocalMaxFilter, localMaxThreshold, cutoffRow, nrows, ncols);

    if debug_cb == true then
      if useScaleB then
        --self.cbScaleB.data = cutil.torch_to_userdata(diffImg_t:byte())
        --self.cbScaleB.data = cutil.torch_to_userdata(ImageProc.yuyv_to_ycbcr_scaleB(yuyvImg, 3))
        --self.cbScaleB.data = cutil.torch_to_userdata(localMaxIdx)
        self.cbScaleB.data = cutil.torch_to_userdata(cb_raw_float_t:byte())
        self.cb.data = cutil.torch_to_userdata(torch.ByteTensor(p_vision.labelA.m, p_vision.labelA.m):fill(0))
      else
        --self.cb.data = cutil.torch_to_userdata(cb_raw_float_t:byte()); 
        self.cb.data = cutil.torch_to_userdata(diffImg_t:byte())
      end
    end

    n_top_bboxes = 8 --5
    if torch.sum(localMaxIdx) > n_top_bboxes then
      localMaxIdx = get_top_n_localMax(localMaxIdx, n_top_bboxes, diffImg_t);
    end
  	self.n_bbox = torch.sum(localMaxIdx);
  	local row,col = find_row_col(localMaxIdx);
  	
  	local bboxLeftTopX = {}
  	local bboxRightBottomX = {}
  	local bboxLeftTopY = {}
  	local bboxRightBottomY = {}


  	for i=1,self.n_bbox do
  	
		-- hack 2019 to make far balls bbox better (long range enhancement hack - use geometry for better)
		-- [[
		if interpl_t[row[i] ] <= 3 then
			interpl_t[row[i] ] = interpl_t[row[i] ] + 1
		end
		-- ]]

  		if useScaleB then
  			bboxLeftTopX[i] = (col[i] - interpl_t[row[i]]) * 2;
  			bboxRightBottomX[i] = (col[i] + interpl_t[row[i]]) * 2;
  			bboxLeftTopY[i] = (row[i] - interpl_t[row[i]]) * 2;
  			bboxRightBottomY[i] = (row[i] + interpl_t[row[i]]) * 2;
  		else
  			bboxLeftTopX[i] = col[i] - interpl_t[row[i]];
  			bboxRightBottomX[i] = col[i] + interpl_t[row[i]];
  			bboxLeftTopY[i] = row[i] - interpl_t[row[i]];
  			bboxRightBottomY[i] = row[i] + interpl_t[row[i]];
  		end	
  		
  		-- RW 2019 Ensure that bboxes stay completly within frame and adjust to keep only ball texture area in view
		if bboxLeftTopX[i] < 1 then
			half_margin = math.floor((-bboxLeftTopX[i] + 1)/2)

			bboxLeftTopX[i] = 1
			bboxRightBottomY[i] = bboxRightBottomY[i] - half_margin
			bboxLeftTopY[i] = bboxLeftTopY[i] + half_margin

		elseif bboxRightBottomX[i] >= y_raw_t:size(2)*2 then
			half_margin = math.floor((bboxRightBottomX[i] - (y_raw_t:size(2)*2 - 1))/2)

			bboxRightBottomX[i] = y_raw_t:size(2)*2 - 1
			bboxRightBottomY[i] = bboxRightBottomY[i] - half_margin
			bboxLeftTopY[i] = bboxLeftTopY[i] + half_margin

		end

		if bboxLeftTopY[i] < 1 then
			half_margin = math.floor((-bboxLeftTopY[i] + 1)/2)

			bboxLeftTopY[i] = 1
			bboxRightBottomX[i] = bboxRightBottomX[i] - half_margin
			bboxLeftTopX[i] = bboxLeftTopX[i] + half_margin
 
		elseif bboxRightBottomY[i] >= y_raw_t:size(1)*2 then
			half_margin = math.floor((bboxRightBottomY[i] - (y_raw_t:size(1)*2 - 1))/2)

			bboxRightBottomY[i] = y_raw_t:size(2)*2 - 1
			bboxRightBottomX[i] = bboxRightBottomX[i] - half_margin
			bboxLeftTopX[i] = bboxLeftTopX[i] + half_margin

		end

	
      --[[ --DP Old 2018
      if (bboxLeftTopX[i] == 0) then
        bboxLeftTopX[i] = bboxLeftTopX[i]+1
        bboxRightBottomX[i] = bboxRightBottomX[i]+1
      end
      if (bboxLeftTopY[i] == 0) then
        bboxLeftTopY[i] = bboxLeftTopY[i]+1
        bboxRightBottomY[i] = bboxRightBottomY[i]+1
      end
      --]]
      
  		self.bboxLeftTopX[i] = bboxLeftTopX[i];
  		self.bboxRightBottomX[i] = bboxRightBottomX[i];
  		self.bboxLeftTopY[i] = bboxLeftTopY[i];
  		self.bboxRightBottomY[i] = bboxRightBottomY[i];

      --DP
      --print(i)
      --print(bboxLeftTopX[i], bboxRightBottomX[i], bboxLeftTopY[i], bboxRightBottomY[i])
  	end

    ---------------------------------------------------------------------------------------
    ----------------------------- END OF REGION PROPOSALS -----------------------------------
    -----------------------------------------------------------------------------------------


  	if self.n_bbox > 0 then
  		self.new_bbox = 1;
  		--print('new bounding boxes')
  	end

    local bboxA;
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

      y_raw_t_scaleA = ImageProc.yuyv_to_ycbcr(yuyvImg, 1)
  		check_passed = checkForBall_NN(self, y_raw_t_scaleA, bboxA);
  		
  		if check_passed then
        self.axisMajor = bboxA[2]-bboxA[1]+1;
  			self.fromRP = 1;
  			break
  		end
    end -- end of for loop for iterating through n_bbox
  end -- end of if statement for entire region proposal + check For Ball stage
----]=====]

  ----------------------------------------------------------------------------------------
  -------------------------------END OF DETECTION-----------------------------------------
  ----------------------------------------------------------------------------------------

  if not check_passed then return end

  --SJ: we subtract foot offset
  --bc we use ball.x for kick alignment
  --and the distance from foot is important
 
  self.ballCentroid = {self.bboxCenterCol, self.bboxCenterRow}
  local scale = 1
  local v = HeadTransform.projectGround(HeadTransform.coordinatesA(self.ballCentroid, scale), self.diameter/2)
  local v_inf = HeadTransform.coordinatesA(self.ballCentroid, 0.1)

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

  --p_vision:add_debug_message(string.format("Ball detected\nv: %.2f %.2f %.2f\n",v[1],v[2],v[3]));
  return
end

local update_shm = function(self, p_vision)
  local cidx = p_vision.camera_index
  if vcm.get_camera_broadcast() > 0 then
    if debug_cb then
      vcm['set_image'..cidx..'_cb'](self.cb.data);
      vcm['set_image'..cidx..'_cbScaleB'](self.cbScaleB.data);
    end
    if debug_RP then
      vcm['set_ball'..cidx..'_newBbox'](self.new_bbox);
      if (self.new_bbox == 1) then
        vcm['set_ball'..cidx..'_bboxLeftTopX'](vector.new(self.bboxLeftTopX));
        vcm['set_ball'..cidx..'_bboxRightBottomX'](vector.new(self.bboxRightBottomX));
        vcm['set_ball'..cidx..'_bboxLeftTopY'](vector.new(self.bboxLeftTopY));
        vcm['set_ball'..cidx..'_bboxRightBottomY'](vector.new(self.bboxRightBottomY));
      end
    end
  end

  vcm['set_ball'..cidx..'_detect'](self.detect);
  if (self.detect == 1) then
    --vcm['set_ball'..cidx..'_color_count'](self.color_count);
    vcm['set_ball'..cidx..'_fromRP'](self.fromRP);
    vcm['set_ball'..cidx..'_centroid'](self.ballCentroid);
    vcm['set_ball'..cidx..'_axisMajor'](self.axisMajor);
    vcm['set_ball'..cidx..'_axisMinor'](0);
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
  self.diameter = Config.vision.ball.diameter;

  self.fromRP = 0;

	self.scaleB = Config.vision.scaleB[cidx];
	
  local filename = '/home/nao/UPennDev/Player/Data/ball_nn_weights/weight_table_model_Ryan2019_1.dat' --RW2019
  --local filename = '/home/nao/UPennDev/Player/Data/ball_nn_weights/weight_table_model16.dat' --DP2018
  local file = torch.DiskFile(filename, 'r')
  local weight_table = file:readObject()
  file:close()

  self.nn_weight_table = weight_table

  return self
end

return detectBall
