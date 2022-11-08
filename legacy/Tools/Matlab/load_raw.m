function [rgb,yuv,ycbcr] = load_raw(strtop,strbtm,ind,teamNumber,playerID)
%[rgb,yuv,ycbcr] = load_yuv(top,btm,ind,1,1);
% Yongbo Qian @ 2015
% This function loads the raw rgb image and the corresponding horizon value
% INPUTS:
% strtop&strbtm: string of image log file. etc: 'yuyv_top_20151122T182617';
% nc: top camera = 1, bottom camera = 2
% nl: label index: labelA = 1, labelB = 2
% ind: image index (1-100)
% teamNumber = 1
% playerID = 1

% OUTPUTS:
% RGB{1} Pixel value of top camera
% RGB{2} Pixel value of btm camera

close all
    global MONITOR
% simulate the robot state from the log file data
  if (nargin < 4)
    teamNumber = 1;
  end
  if (nargin < 5)
    playerID = 1;
  end

%LOGtop = load(strtop);
%LOGbtm = load(strbtm);
% LOGbtm = load(strcat('../Symposium/',strbtm));

LOGtop = load(strcat('logs/',strtop));
LOGbtm = load(strcat('logs/',strbtm));

yuyvMontage = {};
yuyvMontage{1} = LOGtop.yuyvMontage;
yuyvMontage{2} = LOGbtm.yuyvMontage;

for i = 1:2
    yuyv = yuyvMontage{i}(:,:,:,ind);
    siz = size(yuyv);
    yuyv_u8 = reshape(typecast(yuyv(:), 'uint8'), [4 siz]);
    yuv_u8 = yuyv_u8([1 2 4],:, :, :);
% permute the array so it is WxHx3 (from 3xHxW)
    yuv{i} = permute(yuv_u8, [3 2 1 4]);
    ycbcr_tmp = yuyv_u8([1 2 4], :, 1:2:end);
    ycbcr{i} = permute(ycbcr_tmp, [3 2 1]);
    rgb{i} = ycbcr2rgb(ycbcr{i});
    figure(i);
    imagesc(rgb{i});
end
