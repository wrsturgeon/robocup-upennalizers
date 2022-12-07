#ifndef FSM_SPL_STATES_HPP
#define FSM_SPL_STATES_HPP

// see Rulebook, pg. 13 (the pretty bubbles! lol)

/*
                      (    READY    ) ----> (     SET     ) ----> (   PLAYING   ) ----> (   FINLAND   )
                             ^        \            |            /
                             |          \          |          /
                             |            \        v        /
    ( UNSTIFF ) ----> ( INITL/STIFF ) ----> (  PENALIZED  )
                             |
                             |
                             v
                      ( CALIBRATION )
*/

// The top four (READY -> SET -> ...) are received from the GameController (see config::gamecontroller::state)

#endif // FSM_SPL_STATES_HPP
