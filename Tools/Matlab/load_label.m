function [label, horizon]=load_label(strim,nc,nl,ind,teamNumber,playerID)
% Yongbo Qian @ 2015
% This function loads the label image and the horizon value of that image
% strim: string of image log file. etc: strim = 'yuyv_top_20151122T182617';
% nc: top camera = 1, bottom camera = 2
% nl: label index: labelA = 1, labelB = 2
% ind: image index (1-100)
% teamNumber = 1
% playerID = 1

close all
  global MONITOR
% simulate the robot state from the log file data
  if (nargin < 5)
    teamNumber = 1;
  end
  if (nargin < 6)
    playerID = 1;
  end
  r = shm_robot_nao(teamNumber, playerID);

  % set yuyv_type to full size images
  r.vcmCamera.set_yuyvType(1); 
  r.vcmCamera.set_broadcast(1);

  LOGim = load(strcat('logs/',strim));
  
  LOG = LOGim.LOG;
  yuyvMontage = LOGim.yuyvMontage;
  % store image in shared memory
  r.set_yuyv(yuyvMontage(:,:,:,ind),nc);
  
  % extract log struct from cell array
  l = LOG{ind};
  
  % store camera status info
  r.vcmImagetop.set_width(l.camera.width);
  r.vcmImagetop.set_height(l.camera.height);
  r.vcmImagetop.set_headAngles(l.camera.headAngles);
  r.vcmImagetop.set_time(time());
  
  % Load Horizon Value
  
  labelAm = r.vcmImagetop.get_width()/2;
  labelBm = labelAm/r.vcmImagetop.get_scaleB();
  horizonDir = r.vcmImagetop.get_horizonDir();
  horizonA = r.vcmImagetop.get_horizonA();
  horizonB = r.vcmImagetop.get_horizonB();
      
  % Draw Label Image 
  if nl == 1   
     label = r.get_labelA(nc);
     plot_label(label)
     horizon = horizonA;
  else
     label = r.get_labelB(nc);
     plot_label(label)
     horizon = horizonB;
  end
  display(horizon,'horizon')
end
