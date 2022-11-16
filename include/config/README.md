# Calibrated parameters

Some of these are manual and require a few seconds of work per year (when rules change).

Apart from the main game executable,
there will also be executables that
run a game-like exploration environment
to calibrate various metrics ahead of time.

These executables will then write
C++ header files to this folder
(with about 3 billion `inline constexpr`s),
which can then be `#include`d
in gameplay files _at compile time_.
