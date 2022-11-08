#ifndef lua_im_rescale_DP_h_DEFINED
#define lua_im_rescale_DP_h_DEFINED

#include <stdint.h>
#include <iostream>

#include <lua.hpp>
#include <torch/TH/TH.h>
#include <torch/luaT.h>

#include "im_rescale_DP.h"

int lua_im_rescale_idx(lua_State *L);
int lua_bilinear_interp(lua_State *L);

#endif
