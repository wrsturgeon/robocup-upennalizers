# UPennalizers

Forked from the original (c. 2019, GitLab); iterative improvements.

New code can be compiled by `cd`ing to `src/` and using `./compile [path/to/file] [--release/--debug]`, which creates an executable at `bin/robocup-[file]`. Compile the entire game routine with `./compile start.cpp --release`, which creates `../bin/robocup-start`.

When `ssh`'d into a robot, use `../bin/robocup-start &` to keep the robot playing when you disconnect. The ampersand tells the OS to run `robocup-start` in the background; the side-effect is that you can't stop it until the GameController says the game is over, unless you lookup the process and kill it from the outside with `killall robocup-start`.

Legacy code can be run by `cd`ing to `legacy/Player/` and using `./game main`.

### Description from the legacy codebase:

The project began with the University of Pennsylvania RoboCup code base from
the 2011 RoboCup season and is continuing to evolve into an ever more
generalized and versatile robot software framework.

Documentation:
  The GitHub Wiki hosts the main source of documentation for this project:
    - https://github.com/UPenn-RoboCup/UPennalizers/wiki 

Contact Information:
  UPenn EMail:      upennalizers@gmail.com
  UPenn Website:    https://fling.seas.upenn.edu/~robocup/wiki/

