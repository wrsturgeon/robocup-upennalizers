function LearnColor(team,player)
%-----------------------------------------------------
%
%  Usage: LearnColor(1,2)       : name team and playerID
%  	  		LearnColor()          : use team 1 and playerID 1
%
%-----------------------------------------------------

  global COLORTABLE SHM_DIR_LINUX SHM_DIR_OSX ROBOT;

  % Initiate colortable structure
  if ~isempty(COLORTABLE)
    clear global COLORTABLE;
  end

  colortable_init;

  if ismac == 1
    SHM_DIR='/tmp/boost_interprocess';  
  elseif isunix == 1
    SHM_DIR='/dev/shm';
  end

  tFPS = 8; % Target FPS
  dInterval = 5; %Vision update interval for team view
  dInterval = 1; 

%%%%% Init SHM for robots
  t0=tic;

  if nargin==2  %2 args... track specified player 
    team2track=team;player2track=player;
  else
    %Default value is 1,1 
    %listen_monitor and listen_team_monitor saves to this SHM
    team2track = 1;player2track = 1;
  end
  for i=1:length(player2track)
    if shm_check(team2track,player2track(i))==0 
      disp('Team/Player ID error!');
      return;
    end
    ROBOT=shm_robot(team2track,player2track(i));
  end

  yuyv_type = ROBOT.vcmCamera.get_yuyvType();
  if yuyv_type == 1
    img_size = size(ROBOT.get_yuyv()); 
  elseif yuyv_type == 2
    img_size = size(ROBOT.get_yuyv2());
  elseif yuyv_type == 3
    img_size = size(ROBOT.get_yuyv3());
  else
    return;
  end

%% Init Colortable GUI display

  img_size
  LEARNCOLOR = colortable_online();
  LEARNCOLOR.Initialize(img_size);
  t = toc( t0 );
  fprintf('Initialization time: %f\n',t);

%% Enter loop

  %% Update our plots
  nUpdate = 0;
  while 1
    nUpdate = nUpdate + 1;
    LEARNCOLOR.update(yuyv_type);
  end

%% subfunction for checking the existnace of SHM
  function h = shm_check(team, player)
    %Checks the existence of shm with team and player ID
    shm_name_wcmRobot = sprintf('%s/vcmImage%d%d%s', SHM_DIR, team, player, getenv('USER'));
    h = exist(shm_name_wcmRobot,'file');
  end

end
