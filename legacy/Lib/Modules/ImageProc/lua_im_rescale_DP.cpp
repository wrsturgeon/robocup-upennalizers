#include "lua_im_rescale_DP.h"

int lua_im_rescale_idx(lua_State *L) {
  long *idx_src = (long *) lua_touserdata(L, 1);
  long *idx_dst = (long *) lua_touserdata(L, 2);
  float *idx_s2d = (float *) lua_touserdata(L, 3);
  long *idx_left = (long *) lua_touserdata(L, 4);
  float Ks = luaL_checknumber(L, 5);
  float Kd = luaL_checknumber(L, 6);

  im_rescale_idx(idx_src, idx_dst, idx_s2d, idx_left, Ks, Kd);

  return 1;
}

int lua_bilinear_interp(lua_State *L) {
  float *img_src = (float *) lua_touserdata(L, 1);
  float *img_dst = (float *) lua_touserdata(L, 2);
  float *idx_s2d = (float *) lua_touserdata(L, 3);
  long *idx_left = (long *) lua_touserdata(L, 4);
  int Ks = luaL_checkint(L, 5);
  int Kd = luaL_checkint(L, 6);
 
  bilinear_interp(img_src, img_dst, idx_s2d, idx_left, Ks, Kd);

  return 1;
}