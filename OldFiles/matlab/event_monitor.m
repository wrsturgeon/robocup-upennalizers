function h = event_monitor(ncamera)
  h.init = @init;
  h.update = @update;

  h.label_select = 0; % 0 for A and 1 for B
  h.field_type= 0; %0,1,2 for SPL/Kid/Teen
  h.enable_debug_msg = 0;
  h.map_type = 1;
  h.logging = 0;
  h.scale = 1.5; % scale size of plotting on map

  % logger
  h.logger = logger(ncamera);

  % kinds of drawer
  h.draw_overlay = draw_overlay;

  % monitor-wise params
  h.ncamera = ncamera;

  % monitor-wise cache params
  h.robot = [];
  h.team = [];

  % layout
  h.grid_height = 4;
  h.grid_width = ncamera + 2;
  % generate layout for all windows
  h.layouts = cell(h.grid_height / 2 * h.grid_width, 1);
  layouts_idx = 1;
  for r = 1 : 2 : h.grid_height
    for c = 1 : h.grid_width
      h.layouts{layouts_idx} = [(r-1) * h.grid_width + c, r * h.grid_width + c];
      layouts_idx = layouts_idx + 1;
    end
  end
  
  % assign layout for different subplots
  layout_num = 1 : h.grid_height * h.grid_width / 2;
  h.global_map_layout = h.layouts{1};
  layout_num(layout_num == 1) = [];
  h.local_map_layout = h.layouts{1 + h.grid_width};
  layout_num(layout_num == (1 + h.grid_width)) = [];

  layout_num(layout_num == (h.grid_width)) = [];
  layout_num(layout_num == (2 * h.grid_width)) = [];
  layout_num(layout_num == (3 * h.grid_width)) = [];
  layout_num(layout_num == (4 * h.grid_width)) = [];

  h.rgb_layout = cell(ncamera);
  h.label_layout = cell(ncamera);
  layouts_idx = 1;
  for nc = 1 : ncamera
    h.rgb_layout{nc} = h.layouts{layout_num(layouts_idx)}; 
    layouts_idx = layouts_idx + 1;
    h.label_layout{nc} = h.layouts{layout_num(layouts_idx)};
    layouts_idx = layouts_idx + 1;
  end

  % color map
   cbk=[0 0 0];cr=[1 0 0];cg=[0 1 0];cb=[0 0 1];cy=[1 1 0];cw=[1 1 1];cbrc=[0.5 0.5 1];cbrp=[1 0.5 0.5];
   h.cmap=[cbk;cr;cy;cy;cb;cb;cb;cb;cg;cg;cg;cg;cg;cg;cg;cg];
   cmapw = repmat(cw,16,1);
   h.cmap = [h.cmap;cmapw];
   cmaprc = repmat(cbrc,32,1);
   h.cmap = [h.cmap;cmaprc];
   h.cmap(end+1,:) = cbrp;
  init();

  function ret = init()
    % set Monitor window size
    screen_size = get(0, 'ScreenSize');
    screen_width = screen_size(3);
    screen_height = screen_size(4);
    if h.ncamera == 1
      win_width = 830;
      win_height = 400;
    elseif h.ncamera == 2
      win_width = 1100;
      win_height = 400;
    elseif h.ncamera == 3
      win_width = 900;
      win_height = 400;
    end
    fig = figure('Position', [screen_width/2-win_width/2,...
                  screen_height/2-win_height/2, win_width, win_height]);
    clf;

    h.FpsText=uicontrol('Style','text',...
	                      'Units','Normalized',...
                        'Position',[.30 0.94 0.20 0.04]);

    h.Button6=uicontrol('Style','pushbutton','String','FPS -',...
                      	'Units','Normalized',...
                        'Position',[.20 .94 .10 .04],'Callback',@button6);

    h.Button7=uicontrol('Style','pushbutton','String','FPS +',...
                      	'Units','Normalized', 'Position',[.50 .94 .10 .04],'Callback',@button7);

    h.Button12=uicontrol('Style','pushbutton','String','Load LUT',...
                      	'Units','Normalized', 'Position',[.60 .94 .20 .04],'Callback',@button12);

    h.Button0=uicontrol('Style','pushbutton','String','Overlay 1',...
                      	'Units','Normalized', 'Position',[.02 .80 .07 .07],'Callback',@button0);

    h.Button2=uicontrol('Style','pushbutton','String','LABEL A',...
                      	'Units','Normalized', 'Position',[.02 .73 .07 .07],'Callback',@button2);

    h.Button3=uicontrol('Style','pushbutton','String','MAP1',...
                      	'Units','Normalized', 'Position',[.02 .66 .07 .07],'Callback',@button3);

    h.Button4=uicontrol('Style','pushbutton','String','2D ON',...
                      	'Units','Normalized', 'Position',[.02 .59 .07 .07],'Callback',@button4);

    h.Button5=uicontrol('Style','pushbutton','String','DEBUG ON',...
                      	'Units','Normalized', 'Position',[.02 .52 .07 .07],'Callback',@button5);

    h.Button11=uicontrol('Style','pushbutton','String','LOG',...
                      	'Units','Normalized', 'Position',[.02 .45 .07 .07],'Callback',@button11);

    h.InfoText=uicontrol('Style','text',...
                      	'Units','Normalized', 'Position',[.02 .25 .07 .20]);

    h.Button13=uicontrol('Style','pushbutton','String','Kidsize',...
            	          'Units','Normalized', 'Position',[.02 .18 .07 .07],'Callback',@button13);

    h.DebugText=uicontrol('Style','edit', 'Enable', 'inactive',...
                        'Max', 2, 'Min', 0, 'HorizontalAlignment', 'center',...
                        'ForegroundColor', 'k',...
	                      'Units','Normalized', 'Position',[.72 .10 .25 .83]);

    % subplot axex handles
    % global map
    h.global_axes_handle = subplot(h.grid_height, h.grid_width, h.global_map_layout);
    set(h.global_axes_handle, 'YDir', 'reverse');
    h.local_axes_handle = subplot(h.grid_height, h.grid_width, h.local_map_layout);
    set(h.local_axes_handle, 'YDir', 'reverse');

    for nc = 1 : h.ncamera
      h.label_axes_handle(nc) = subplot(h.grid_height, h.grid_width, h.label_layout{nc});
      colormap(h.label_axes_handle(nc), h.cmap);
      set(h.label_axes_handle(nc), 'YDir', 'reverse');
      h.rgb_axes_handle(nc) = subplot(h.grid_height, h.grid_width, h.rgb_layout{nc});
      colormap(h.rgb_axes_handle(nc), h.cmap);
      set(h.rgb_axes_handle(nc), 'YDir', 'reverse');

      % handlevisibility must be set to off, otherwise
      % the image handle will be destroyed during overlay plotting
      h.rgb_handle(nc) = image('Parent', h.rgb_axes_handle(nc),...
                                'HandleVisibility', 'off',...
                                'CData', [],...
                                'XData', [1 640],...
                                'YData', [1 480]);
      h.label_handle(nc) = image('Parent', h.label_axes_handle(nc),...
                                'HandleVisibility', 'off',...
                                'CData', [],...
                                'XData', [1 640],...
                                'YData', [1 480]);
    end

  end

  function button13(varargin)
    h.field_type=mod(h.field_type+1,3);
    if h.field_type==1 set(h.Button13,'String', 'SPL');
    elseif h.field_type==2 set(h.Button13,'String', 'TeenSize');
    else set(h.Button13,'String', 'Kidsize');
    end
  end

  function button2(varargin)
    h.label_select = 1- h.label_select;
    if h.label_select == 0 
      set(h.Button2,'String', 'LABEL A');
    elseif h.label_select == 1 
      set(h.Button2,'String', 'LABEL B');
    end
  end

  function button3(varargin)
    % level 1 : pos only
    % level 2 : pos + vision info
    % level 3 : pos + vision info + fov info
    % level 4 : pos + vision info + fov info + partical 
    % level 5 : reverse for occupany map
    h.map_type=mod(h.map_type+1,6);
    if h.map_type==1 set(h.Button3,'String', 'MAP1');
    elseif h.map_type==2 set(h.Button3,'String', 'MAP2');
    elseif h.map_type==3 set(h.Button3,'String', 'MAP3');
    elseif h.map_type==4 set(h.Button3,'String', 'PVIEW');
    elseif h.map_type==5 set(h.Button3,'String', 'OccVIEW');
    else set(h.Button3,'String', 'MAP OFF');
    end

  end

  function button5(varargin)
    h.enable_debug_msg = mod(h.enable_debug_msg + 1, h.ncamera + 2);
    if h.enable_debug_msg == 0 
      set(h.Button5,'String', 'DEB OFF');
    elseif h.enable_debug_msg == 1
      set(h.Button5,'String', 'VDEB 1');
    elseif h.enable_debug_msg == 2
      set(h.Button5,'String', 'VDEB 2');
    elseif h.enable_debug_msg == 3
      set(h.Button5,'String', 'WDEB ON');
    else
      set(h.Button5,'String', '');
    end
  end

  function button11(varargin)
    h.logging=1-h.logging;
  end

  % callback handles
  h.callback_s_yuyv1 = @callback_s_yuyv1;
  function callback_s_yuyv1(st_img)
    callback_s_yuyv(st_img, 1);
  end

  h.callback_s_yuyv2 = @callback_s_yuyv2;
  function callback_s_yuyv2(st_img)
    callback_s_yuyv(st_img, 2);
  end

  function callback_s_yuyv(st_img, cidx)
    if strcmp(char(st_img.type),'jpg') == 1
      rgb = djpeg(st_img.data);
    else
      yuyv = reshape(typecast(st_img.data, 'uint32'), st_img.width/2, st_img.height);
      [ycbcr, rgb] = yuyv2rgb(yuyv);
      % logging
      if h.logging == 1
        h.logger.log_data(yuyv, cidx);
        count = h.logger.get_count(cidx);
        logstr=sprintf('%d/100',count);
        set(h.Button11,'String', logstr);
        if count== 100
          h.logger.save_log();
        end
      end
    end
    set_image(h.rgb_axes_handle(cidx), h.rgb_handle(cidx), rgb);
  end
 
  h.callback_s_labelA1 = @callback_s_labelA1;
  function callback_s_labelA1(st_img)
    callback_s_labelA(st_img, 1);
  end

  h.callback_s_labelA2 = @callback_s_labelA2;
  function callback_s_labelA2(st_img)
    callback_s_labelA(st_img, 2);
  end
  function callback_s_labelA(st_img, cidx)
    label = reshape(st_img.data, st_img.width, st_img.height)';
    if h.label_select == 0
      set_image(h.label_axes_handle(cidx), h.label_handle(cidx), label);
    end
  end

  h.callback_s_labelB1 = @callback_s_labelB1;
  function callback_s_labelB1(st_img)
    callback_s_labelB(st_img, 1);
  end

  h.callback_s_labelB2 = @callback_s_labelB2;
  function callback_s_labelB2(st_img)
    callback_s_labelB(st_img, 2);
  end
  function callback_s_labelB(st_img, cidx)
    label = reshape(st_img.data, st_img.width, st_img.height)';
    if h.label_select == 1
      set_image(h.label_axes_handle(cidx),...
                h.label_handle(cidx), label);
    end
  end

  h.callback_s_vcmdebug1 = @callback_s_vcmdebug1;
  function callback_s_vcmdebug1(st)
    if h.enable_debug_msg == 1
      h.callback_s_debug(st);
    end
  end

  h.callback_s_vcmdebug2 = @callback_s_vcmdebug2;
  function callback_s_vcmdebug2(st)
    if h.enable_debug_msg == 2
      h.callback_s_debug(st);
    end
  end

  h.callback_s_debug = @callback_s_debug;
  function callback_s_debug(st, cidx)
    if size(st.message, 2) > 0
      set(h.DebugText,'String',char(st.message));
    end
  end

  h.callback_s_wcmdebug = @callback_s_wcmdebug;
  function callback_s_wcmdebug(st)
    if h.enable_debug_msg == 3
      h.callback_s_debug(st);
    end
  end

  h.callback_s_gcmteam = @callback_s_gcmteam;
  function callback_s_gcmteam(st)
    % update team cache
    h.team = st;

    if numel(h.robot) > 0
      draw_robot(h.global_axes_handle, h.robot, h.team, 1.5);
    end
  end

  h.callback_s_wcmrobot = @callback_s_wcmrobot;
  function callback_s_wcmrobot(st)
    % upate robot cache 
    h.robot = st;

    % update plot
    draw_field(h.global_axes_handle, h.field_type);
    if numel(h.team) > 0
      draw_robot(h.global_axes_handle, h.robot, h.team, h.scale);
    end
  end

  h.callback_s_wcmball = @callback_s_wcmball;
  function callback_s_wcmball(st)
    if numel(h.robot) > 0
      draw_ball(h.global_axes_handle, st, h.robot, h.scale);
    end
  end

  h.callback_s_vcmball1 = @callback_s_vcmball1;
  function callback_s_vcmball1(st)
    callback_vcmball(st, 1);
  end

  h.callback_s_vcmball2 = @callback_s_vcmball2;
  function callback_s_vcmball2(st)
    callback_vcmball(st, 2);
  end

  function callback_vcmball(st_ball, cidx)
    h.draw_overlay.plot_ball(h.label_axes_handle(cidx), st_ball, 1);
  end

end
