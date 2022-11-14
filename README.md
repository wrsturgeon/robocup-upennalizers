UPennalizers

Forked from the original (c. 2019, GitLab); iterative improvements.
New code can be compiled by `cd`ing to `src/` and using `./compile start.cpp [--release/--debug]`, which creates the main executable at `bin/start`.
When `ssh`'d into a robot, use `./bin/start &` (with the ampersand) to start play and relinquish control of the process; it'll then continue until the GameController tells it to stop, even if you disconnect or close the terminal. To kill a process running in the background (with the ampersand), use `killall start`.
Legacy code can be run by `cd`ing to `legacy/Player/` and using `./game main`.

Description from the legacy codebase:

The project began with the University of Pennsylvania RoboCup code base from
the 2011 RoboCup season and is continuing to evolve into an ever more
generalized and versatile robot software framework.

Documentation:
  The GitHub Wiki hosts the main source of documentation for this project:
    - https://github.com/UPenn-RoboCup/UPennalizers/wiki 

Contact Information:
  UPenn EMail:      upennalizers@gmail.com
  UPenn Website:    https://fling.seas.upenn.edu/~robocup/wiki/

