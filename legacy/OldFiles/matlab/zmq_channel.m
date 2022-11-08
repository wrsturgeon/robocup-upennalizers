function h = zmq_channel(teamNumber, playerID, ncamera)
  clear zmq;
  global Z_RET;
  user = getenv('USER');
  h.update = @update;
  h.get_yuyv = @get_yuyv;
  h.get_rgb = @get_rgb;
  h.get_labelA = @get_labelA;
  h.get_labelB = @get_labelB;
  h.get_monitor_struct = @get_monitor_struct;

  % init zmq channels 
  h.s_yuyv   = zeros(1, ncamera);
  h.s_labelA = zeros(1, ncamera);
  h.s_labelB = zeros(1, ncamera);
  for nc = 1 : ncamera
    h.s_yuyv(nc)     = zmq('subscribe', ['yuyv', num2str(nc),...
                        num2str(teamNumber), num2str(playerID), user]);
    h.s_labelA(nc)   = zmq('subscribe', ['labelA', num2str(nc),...
                        num2str(teamNumber), num2str(playerID), user]);
    h.s_labelB(nc)   = zmq('subscribe', ['labelB', num2str(nc),...
                        num2str(teamNumber), num2str(playerID), user]);
  end
  h.s_vcm = zmq('subscribe', ['vcm', num2str(teamNumber),...
             num2str(playerID), user]);
  h.s_wcm = zmq('subscribe', ['wcm', num2str(teamNumber),...
             num2str(playerID), user]);
  h.s_gcm = zmq('subscribe', ['wcm', num2str(teamNumber),...
             num2str(playerID), user]);



  Z_RET.rgb_data = cell(1, ncamera);
  Z_RET.yuyv_data = cell(1, ncamera);
  Z_RET.labelA_data = cell(1, ncamera);
  Z_RET.labelB_data = cell(1, ncamera);
  Z_RET.vcm = {};
  Z_RET.wcm = {};
  Z_RET.gcm = {};

  function ret = update()
    [data, idx] = zmq('poll', 1000);
    for s = 1 : numel(idx)
      s_idx = idx(s);
      for nc = 1 : ncamera 
        if s_idx == h.s_yuyv(nc);
          st_img = msgpack('unpack', data{s});
          if numel(st_img) > 0
            if strcmp(char(st_img.type),'jpg') == 1
              Z_RET.rgb_data{nc} = djpeg(st_img.data);
            else
              Z_RET.yuyv_data{nc} = reshape(typecast(st_img.data, 'uint32'),...
                                          st_img.width/2, st_img.height);
              [ycbcr, rgb] = yuyv2rgb(Z_RET.yuyv_data{nc});
              Z_RET.rgb_data{nc} = rgb;
            end
          end
        end
        if s_idx == h.s_labelA(nc)
          st_img = msgpack('unpack', data{s});
          if numel(st_img) > 0
            Z_RET.labelA_data{nc} = reshape(st_img.data, st_img.width, st_img.height);
          end
        end
        if s_idx == h.s_labelB(nc)
          st_img = msgpack('unpack', data{s});
          if numel(st_img) > 0
            Z_RET.labelB_data{nc} = reshape(st_img.data, st_img.width, st_img.height);
          end
        end
      end
      if s_idx == h.s_vcm
        st_cm = msgpack('unpack', data{s});
        if numel(st_cm) > 0
          h.vcm = st_cm;
          Z_RET.vcm = st_cm;
        end
      end
      if s_idx == h.s_wcm
        st_cm = msgpack('unpack', data{s});
        if numel(st_cm) > 0
          h.wcm = st_cm;
          Z_RET.wcm = st_cm;
        end
      end
      if s_idx == h.s_gcm
        st_cm = msgpack('unpack', data{s});
        if numel(st_cm) > 0
          h.gcm = st_cm;
          Z_RET.gcm = st_cm;
        end
      end
    end
    ret = Z_RET;

  end

  function rgb = get_rgb()
    rgb = Z_RET.rgb_data; 
  end
  function labelA = get_labelA()
    labelA = Z_RET.labelA_data;
  end
  function labelB = get_labelB()
    labelB = Z_RET.labelB_data;
  end
  function yuyv = get_yuyv();
    yuyv = Z_RET.yuyv_data;  
  end
  
  function r = get_monitor_struct()
    r = {};

    if isstruct(Z_RET.gcm)
      r.team = struct(...
            'number', Z_RET.gcm.number,...
            'color', Z_RET.gcm.color,...
            'player_id', Z_RET.gcm.player_id,...
            'role', Z_RET.gcm.role()...
            );
    end

    pose = Z_RET.wcm.robot.pose;
    r.robot = {};
    r.robot.pose = struct('x', pose(1), 'y', pose(2), 'a', pose(3));

    % vision debugging msg
    if isstruct(Z_RET.vcm)
      r.debug = {};
      r.debug.message = char(Z_RET.vcm.debug.message);
    end
  end

end
