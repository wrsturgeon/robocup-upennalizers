#ifndef lua_region_proposal_h_DEFINED
#define lua_region_proposal_h_DEFINED

#include <stdint.h>
#include <iostream>

#include <torch/TH/TH.h>
#include <torch/luaT.h>

#include "region_proposal.h"

int lua_integral_image2(lua_State *L);
int lua_high_contrast_parts2(lua_State *L);
int lua_top_most_row2(lua_State *L);
int lua_diff_img2(lua_State *L);
int lua_local_max2(lua_State *L);

#endif