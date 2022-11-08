
local function DP_max_pooling_2d(img, kernel_width)
  local N = img:size(1)
  local h = img:size(2)
  local w = img:size(3)
  local img_reshaped = img:reshape(N, h/2, 2, w/2, 2):transpose(3,4):reshape(N,h/2,w/2,4)
  local max_val = torch.max(img_reshaped, 4):squeeze()

  return max_val
end

local function DP_log_softmax(input)
  local output = torch.log(torch.exp(input)/torch.sum(torch.exp(input)))

  return output
end

function nn_forward(img, weight_table)
  local conv1_weights = weight_table[1]
  local conv1_bias    = weight_table[2]
  local conv2_weights = weight_table[3]
  local conv2_bias    = weight_table[4]
  local linear1_weights = weight_table[5]
  local linear1_bias    = weight_table[6]
  local linear2_weights = weight_table[7]
  local linear2_bias    = weight_table[8]
 
  local output

  -- 1st conv layer
  output = torch.conv2(img, conv1_weights) + conv1_bias

  -- ReLU
  output[output:lt(0)]=0

  -- max pooling
  output = DP_max_pooling_2d(output, 2)

  -- 2nd conv layer
  output = torch.conv2(output, conv2_weights) + conv2_bias

  -- ReLU
  output[output:lt(0)]=0

  -- max pooling
  output = DP_max_pooling_2d(output, 2)

  -- flattening
  output = output:reshape(40,1)

  -- 1st fully connected layer
  output = torch.mm(linear1_weights, output) + linear1_bias

  -- 2nd fully connected layer
  output = torch.mm(linear2_weights, output):squeeze() + linear2_bias

  -- softmax
  output = DP_log_softmax(output)

  return output
end

