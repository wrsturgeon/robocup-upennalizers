module(..., package.seeall);

require('Body')
require('walk')
require('vector')
require('Config')
require('wcm')
require('mcm')
require('velgeneration')

local log = require 'log';
if Config.log.enableLogFiles then
    log.outfile = (Config.log.behaviorFile);
end
log.level = Config.log.logLevel;

timeout = 90;
newphase = 0;

teamSearchType= fsm.searchType or 1;

ROLE_ATTACKER = 1
ROLE_DEFENDER = 2
ROLE_SUPPORTER = 3
ROLE_DEFENDER2 = 4

goal_attack = wcm.get_goal_attack();
goal_defend = wcm.get_goal_defend();

p1Locations = {{0, 0.9*Config.world.yLineBoundary},--left sideline center
         {0, -0.9*Config.world.yLineBoundary}, --right sideline center
         {0,0} --center circle
}

p2Locations = {Config.world.spot[1], --our spot  2
               Config.world.spot[2], --opponents spot  2
}

p3Locations = {{Config.world.Lcorner[5][1], 0.9*Config.world.yLineBoundary}, --our left corner 3
                   {Config.world.Lcorner[5][1], -0.9*Config.world.yLineBoundary}, --our right corner 3
                   {Config.world.Lcorner[7][1], 0.9*Config.world.yLineBoundary},  --opponents left corner 3
                   {Config.world.Lcorner[7][1], -0.9*Config.world.yLineBoundary}, --opponents right corner 3
                   {-0.5*Config.world.xLineBoundary, 0.9*Config.world.yLineBoundary}, --left sideline middle of our side 3
                   {-0.5*Config.world.xLineBoundary, -0.9*Config.world.yLineBoundary}, --right sideline middle of our side 3
                   {0.5*Config.world.xLineBoundary, 0.9*Config.world.yLineBoundary}, --left sideline middle of opponents side 3
                   {0.5*Config.world.xLineBoundary, -0.9*Config.world.yLineBoundary}, --right sideline middle of opponents side 3
}

searchLocations = {{0, 0.9*Config.world.yLineBoundary}, --left sideline center    1
                   {0, -0.9*Config.world.yLineBoundary}, --right sideline center  1
                   Config.world.spot[1], --our spot  2
                   Config.world.spot[2], --opponents spot  2
                   {Config.world.Lcorner[5][1], 0.9*Config.world.yLineBoundary}, --our left corner 3
                   {Config.world.Lcorner[5][1], -0.9*Config.world.yLineBoundary}, --our right corner 3
                   {Config.world.Lcorner[7][1], 0.9*Config.world.yLineBoundary},  --opponents left corner 3
                   {Config.world.Lcorner[7][1], -0.9*Config.world.yLineBoundary}, --opponents right corner 3
                   {-0.5*Config.world.xLineBoundary, 0.9*Config.world.yLineBoundary}, --left sideline middle of our side 3
                   {-0.5*Config.world.xLineBoundary, -0.9*Config.world.yLineBoundary}, --right sideline middle of our side 3
                   {0.5*Config.world.xLineBoundary, 0.9*Config.world.yLineBoundary}, --left sideline middle of opponents side 3
                   {0.5*Config.world.xLineBoundary, -0.9*Config.world.yLineBoundary}, --right sideline middle of opponents side 3
                   {0,0}}; -- center 1


searchStart = {}
searched = vector.zeros(#searchLocations);


function entry()
  log.debug(_NAME.." entry");

  --get some useful info
  num_players = wcm.get_team_players_alive();
  myrole = gcm.get_team_role();
  t0 = Body.get_time();
  phase = 1;

--proposed search technique: look at robot y positions on field and assign center left and right based on which is where.
--if two have the same y then go by closest x
--if two have the same x, fix localization system
--if less than 3 robots then make left and right
--if one then all is good, not really but okay


if (teamSearchType <= 2) then --random and defensive team search
  --figure out where everybody should start searching

  -- poses = TeamSPL.poses;



  -- if num_players <= 2 then
  --    CENTER_SEARCH = ROLE_ATTACKER;
  -- elseif num_players == 3 then

  --   if(poses[ROLE_ATTACKER].y == poses[ROLE_SUPPORTER].y) then
  --     if (poses[ROLE_ATTACKER].x <= poses[ROLE_SUPPORTER].x) and poses[ROLE_ATTACKER].y > 0 then
  --       LEFT_SEARCH = ROLE_ATTACKER;
  --       RIGHT_SEARCH = ROLE_SUPPORTER;
  --     else
  --       RIGHT_SEARCH = ROLE_ATTACKER;
  --       LEFT_SEARCH = ROLE_SUPPORTER;
  --     end
  --   elseif (poses[ROLE_ATTACKER].y > poses[ROLE_SUPPORTER].y) then
  --       LEFT_SEARCH = ROLE_ATTACKER;
  --       RIGHT_SEARCH = ROLE_SUPPORTER;
  --   else
  --       RIGHT_SEARCH = ROLE_ATTACKER;
  --       LEFT_SEARCH = ROLE_SUPPORTER;
  --   end
  -- else
  --   lx, ly, li = poses[1].x, poses[1].y, 1;
  --   rx, ry, ri = poses[1].x, poses[1].y, 1;
  --   for i=1, 3 do
  --     if(poses[i].y<ry) then
  --       rx, ry, ri = poses[i].x, poses[i].y, i;
  --     elseif (poses[i].y>ly) then
  --       lx, ly, li = poses[i].x, poses[i].y, i;
  --     else
  --       ci = i
  --     end
  --   end
  -- end
  --   for i=1, 4 do
  --     searchStart[i] = searchLocation[13];
  --   end
  --   searchStart[LEFT_SEARCH] = searchLocation[1];
  --   searchStart[RIGHT_SEARCH] = searchLocation[2];
  --   searchStart[CENTER_SEARCH] = searchLocation[13];

   --OLD CODE:

  if num_players <= 2 then
    searchStart[ROLE_ATTACKER] = searchLocations[4]; --left sideline /changed to opponents spot
   searchStart[ROLE_DEFENDER] = searchLocations[2]; --right sideline
    searchStart[ROLE_SUPPORTER] = searchLocations[5]; --doesn't matter
    searchStart[ROLE_DEFENDER2] = searchLocations[5]; --doesn't matter
  elseif num_players == 3 then
    searchStart[ROLE_ATTACKER] = searchLocations[4];--right sideline /changed to opponents spot
    searchStart[ROLE_DEFENDER] = searchLocations[3]; --our spot
    searchStart[ROLE_SUPPORTER] = searchLocations[1]; --left sideline  either defender 2 or support will be active
    searchStart[ROLE_DEFENDER2] = searchLocations[1];
  else

    searchStart[ROLE_ATTACKER] = searchLocations[4]; --opponents spot
    searchStart[ROLE_DEFENDER] = searchLocations[2]; --right sideline
    searchStart[ROLE_SUPPORTER] = searchLocations[1]; --left sideline
    searchStart[ROLE_DEFENDER2] = searchLocations[3]; --our spot
  end


elseif (teamSearchType == 3) then --

 -- :TODO implement eventually a second more attacking team search


else

 -- :TODO implement eventually a third zonal positioning based team search


end

end


--next, sort things into catagories based on priority.
--have the robots keep searching locations and assign new ones based on lowest (priority *  priority)+closeness value.
--put priorities as 1, 2, 3. with the start locations being set as the closest position in priority 1 that isnt already occupied.
-- put distance as the actual r distance between current position and the position we want. ex the local dist function


function update()

  --go to initial search location
  if phase == 1 then
    walkTo = searchStart[myrole];

  --otherwise figure out where next place to walk is
  elseif newphase == 1 then
    walkTo = FindNextSearch(newphase);

  else --just update where teammates are going
    updateSearched()
  end

  --log.debug("WalkTo:", unpack(walkTo));
  --print('WalkTo:',unpack(walkTo));

  --set walk to go to search location
  gcm.set_game_walkingto(walkTo);
  vx,vy,va = velgeneration.getRoleSpecificVelocity({walkTo[1],walkTo[2],0});
  walk.set_velocity(vx, vy, va);

  --figure out if we have made it to our search location
  pose = wcm.get_pose();
  if closeTo(walkTo,{pose.x,pose.y}) then
    log.debug("Reached search location at", unpack(walkTo));
    phase = phase + 1;
    newphase = 1;
  end

  --check if we have seen the ball
  t = Body.get_time();
  ball = wcm.get_ball();
  -- if (t - ball.t < 0.2) and ball.p > 0.5 then

  --print("wcm.get_robot_team_ball_score() ", wcm.get_robot_team_ball_score())
  if (t - ball.t < 0.5) and wcm.get_robot_team_ball_score() > 0.4 then --Yongbo suggests, change this to an or instead of an and
    log.debug("Transition: ball");
    return "ball";
  end

  --Timeout if we have been here too long
  if (t-t0) > timeout then
        log.debug("Transition: search timeout");
    return "timeout";
  end

  --if we have searched many locations just give up
  if phase > 4 then
    log.debug("Transition: done");
    return "done";
  end

end


function exit()
    mcm.set_walk_isSearching(0);
end


--function to compare closeness of two 2d locations
function closeTo(loc1, loc2)
    thresh = 0.65;
    xerr = math.abs(loc1[1] - loc2[1]);
    yerr = math.abs(loc1[2] - loc2[2]);
    if xerr < thresh and yerr < thresh then
        return true
    else
        return false
    end
end


--update which locations have been searched by team
function updateSearched()

    --get team info about where everybody is going
    walkingTo = {}
    walkingTo[ROLE_ATTACKER] = wcm.get_team_attacker_walkTo();
    walkingTo[ROLE_DEFENDER] = wcm.get_team_defender_walkTo();
    walkingTo[ROLE_SUPPORTER] = wcm.get_team_supporter_walkTo();
    walkingTo[ROLE_DEFENDER2] = wcm.get_team_defender2_walkTo();

    --check to see if current destination of any robots matches search locations
    for i=1,4 do
        if walkingTo[i] then --and not closeTo(walkingTo[i],{0,0}) then
            for j = 1,#searchLocations do
                --print('WalkingTo:',unpack(walkingTo[i]));
                --print('Search Locations:',unpack(searchLocations[j]));
                if searched[j] == 0 and closeTo(walkingTo[i],searchLocations[j]) then
                    searched[j] = 1;
                end
            end
        end
    end
end


--find next place to look for ball
function FindNextSearch()

  newphase = 0;
  updateSearched();

  --figure out how many locations left to search there are
  stillAvailable = {};
  priorities = {};
  numAvailable = 0;
  for i=1,#searchLocations do
    if searched[i] == 0 then
      --check what type of search we're using, if we're defensive only go to locations in our half
      if teamSearchType == 2 then
        if (searchLocations[i])[1] > 0.2 then
          searched[i] = 1;
        else
          numAvailable = numAvailable + 1;
          stillAvailable[numAvailable] = i;
          priorities[i] = getPriority(searchLocations[i]);
        end
      else
        numAvailable = numAvailable + 1;
        stillAvailable[numAvailable] = i;
        priorities[i] = getPriority(searchLocations[i])
      end
    end
  end

    --make sure there are still locations left
    if numAvailable == 0 then
        walkTo = {0,0};
    else
  --your time to shine. pick the lowest priority that isnt nil
  minID=0
        for i=1,#searchLocations do
           if(priorities[i] ~= NAN) then
              if (minID == 0) then
                minID = i
              elseif(minID > priorities[i]) then
                minID = i
              end
     end
  end

  walkTo = searchLocations[minID];
     end

--OldCode:

        --pick a random location from ones we haven't checked yet
--        idx = math.random(numAvailable);
--        locIdx = stillAvailable[idx];
--        walkTo = searchLocations[locIdx];
--    end

    return walkTo

end

function getPriority(loc)
  --print("loc", loc)
  pose = wcm.get_pose()
  priority = 0;
  for i=1, #p1Locations do
    if (p1Locations[i][1] == loc[1] and p1Locations[i][1] == loc[1] and p1Locations[i][3] == loc[3]) then
      priority = 1
    end
  end
  for i=1, #p2Locations do
    if (p2Locations[i][1] == loc[1] and p2Locations[i][1] == loc[1] and p2Locations[i][3] == loc[3]) then
      priority = 2
    end
  end
  for i=1, #p3Locations do
    if (p3Locations[i][1] == loc[1] and p3Locations[i][1] == loc[1] and p3Locations[i][3] == loc[3]) then
      priority = 3
    end
  end
  return math.sqrt((loc[1]-pose.x)^2 + (loc[2]-pose.y)^2 ) + priority^2
end
