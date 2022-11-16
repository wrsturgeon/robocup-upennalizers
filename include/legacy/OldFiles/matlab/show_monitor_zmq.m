function h = show_monitor_zmq(ncamera)
  global LOGGER;
  h.init = @init;
  h.update = @update;

  h.field_type= 0; %0,1,2 for SPL/Kid/Teen
  h.enable_debug_msg = 1;
  h.logging = 0;

  % monitor-wise params
  h.ncamera = ncamera;
  h.label_select = 1; % 0 for A and 1 for B

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
      win_width = 530;
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

    h.DebugText=uicontrol('Style','text',...
	          'Units','Normalized', 'Position',[.73 .10 .22 .83]);

    % subplot axex handles
    % global map
    h.global_map_handle = subplot(h.grid_height, h.grid_width, h.global_map_layout);
    h.local_map_handle = subplot(h.grid_height, h.grid_width, h.local_map_layout);
    for nc = 1 : h.ncamera
      h.label_axes_handle(nc) = subplot(h.grid_height, h.grid_width, h.label_layout{nc});
      colormap(h.label_axes_handle(nc), h.cmap);
      set(h.label_axes_handle(nc), 'YDir', 'reverse', 'Units', 'Normalized');
      h.rgb_axes_handle(nc) = subplot(h.grid_height, h.grid_width, h.rgb_layout{nc});
      colormap(h.rgb_axes_handle(nc), h.cmap);
      set(h.rgb_axes_handle(nc), 'YDir', 'reverse', 'Units', 'Normalized');
      h.rgb_handle(nc) = image('Parent', h.rgb_axes_handle(nc),...
                                'CData', [],...
                                'XData', [1 640],...
                                'YData', [1 480]);
      h.label_handle(nc) = image('Parent', h.label_axes_handle(nc),...
                                'CData', [],...
                                'XData', [1 640],...
                                'YData', [1 480]);
    end

    LOGGER = logger();
    LOGGER.init(h.ncamera);
  end

  function update(robot_zmq)
    r_mon = robot_zmq.get_monitor_struct();

    % global map
    h.global_map_handle = subplot(h.grid_height, h.grid_width, h.global_map_layout);
    plot_field(h.global_map_handle, h.field_type);
    
    % local map
    h.local_map_handle = subplot(h.grid_height, h.grid_width, h.local_map_layout);

    % RGB
    for nc = 1 : h.ncamera
      h.rgb_handle(nc) = subplot(h.grid_height, h.grid_width, h.rgb_layout{nc});
      rgb = robot_zmq.get_rgb();
      if numel(rgb{nc}) > 0
        image(rgb{nc});
      end
    end

    % label
    for nc = 1 : h.ncamera
      h.label_handle(nc) = subplot(h.grid_height, h.grid_width, h.label_layout{nc});
      if h.label_select == 0
        label = robot_zmq.get_labelA();
        if numel(label{nc}) > 0
          plot_label(label{nc}');
        end
      elseif h.label_select == 1
        label = robot_zmq.get_labelB();
        if numel(label{nc}) > 0
          plot_label(label{nc}');
        end
      end
    end

    % update debugging msg
    if h.enable_debug_msg == 1
      set(h.DebugText,'String',r_mon.debug.message);
    end
    
    % logging
    if h.logging == 1
      LOGGER.log_data(robot_zmq.get_yuyv());
      logstr=sprintf('%d/100',LOGGER.log_count(1));
      set(h.Button11,'String', logstr);
      if LOGGER.log_count== 100
        LOGGER.save_log();
      end
    end

    drawnow;

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

  function button5(varargin)
    h.enable_debug_msg=1-h.enable_debug_msg;
    if h.enable_debug_msg set(h.Button5,'String', 'DEBUG ON');
    else set(h.Button5,'String', 'DEBUG OFF');
      set(h.DebugText,'String','');
    end
  end

  function button11(varargin)
    h.logging=1-h.logging;
  end

end
