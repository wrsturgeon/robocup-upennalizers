function h = zmq_robot(teamNumber, playerID, ncamera, monitor)
  clear zmq;
  h.MONITOR = monitor;
  h.update = @update;

  % init zmq channels from shm
  user = getenv('USER');
  lua_ins = lua;
  cm_channels = struct(...
    'vcm', lua_ins.load_cm_struct('vcm'),...
    'gcm', lua_ins.load_cm_struct('gcm'),...
    'wcm', lua_ins.load_cm_struct('wcm')...
  );

  % iterate communication manager name to generate channels
  cm_names = fieldnames(cm_channels);
  for cm = 1 : numel(cm_names)
    cm_name = cm_names{cm};
    field_names = fieldnames(cm_channels.(cm_name));
    % iterate field name
    for fm = 1 : numel(field_names)
      field_name = field_names{fm};
      % open zmq channels based on cm and fm
      h.channels.(['s_' cm_name field_name]) = zmq('subscribe',...
                 [cm_name field_name num2str(teamNumber) num2str(playerID) user]);
    end
  end
  for nc = 1 : ncamera
    h.channels.(['s_yuyv' num2str(nc)])   = zmq('subscribe',...
                ['vcmyuyv', num2str(nc), num2str(teamNumber), num2str(playerID), user]);
    h.channels.(['s_labelA' num2str(nc)]) = zmq('subscribe',...
                ['vcmlabelA', num2str(nc), num2str(teamNumber), num2str(playerID), user]);
    h.channels.(['s_labelB' num2str(nc)]) = zmq('subscribe',...
                ['vcmlabelB', num2str(nc), num2str(teamNumber), num2str(playerID), user]);
  end
  h.channel_names = fieldnames(h.channels);

  function update()
    [data, idx] = zmq('poll', 1000);
    for s = 1 : numel(idx)
      s_idx = idx(s);
      % iterate to find match message : filter
      for chn = 1 : numel(h.channel_names)
        if s_idx == h.channels.(h.channel_names{chn})
          if isfield(h.MONITOR, ['callback_' h.channel_names{chn}]) > 0
            h.MONITOR.(['callback_' h.channel_names{chn}])(msgpack('unpack', data{s}));
          end
        end
      end
    end
  end

end
