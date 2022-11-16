#include "lua_region_proposal.h"

int lua_integral_image2(lua_State *L) {
  float *dst = (float *) lua_touserdata(L, 1);
  float *src = (float *) lua_touserdata(L, 2);
  int nrows = luaL_checkint(L, 3);
  int ncols = luaL_checkint(L, 4);
  int stride = luaL_checkint(L, 5);

  integral_image(dst, src, nrows, ncols, stride);

  return 1;
}

int lua_high_contrast_parts2(lua_State *L) {
  uint8_t *dst = (uint8_t *) lua_touserdata(L, 1);
  float *y = (float *) lua_touserdata(L, 2);
  float *y_intImg = (float *) lua_touserdata(L, 3);
  float *br = (float *) lua_touserdata(L, 4);
  int minRadius = luaL_checkint(L, 5);
  int width = luaL_checkint(L, 6);
  int cidx = luaL_checkint(L, 7);
  int nrows = luaL_checkint(L, 8);
  int ncols = luaL_checkint(L, 9);
 
  high_contrast_parts(dst, y, y_intImg, br, 
                      minRadius, width, cidx, 
                      nrows, ncols);

  return 1;
}

int lua_top_most_row2(lua_State *L) {
  float *src = (float *) lua_touserdata(L, 1);
  int nrows = luaL_checkint(L, 2);
  int ncols = luaL_checkint(L, 3);
 
  int topMostRow = top_most_row(src, nrows, ncols);
  lua_pushnumber(L, topMostRow);

  return 1;
}

int lua_diff_img2(lua_State *L) {
  float *dst = (float *) lua_touserdata(L, 1);
  float *src = (float *) lua_touserdata(L, 2);
  uint8_t *mask = (uint8_t *) lua_touserdata(L, 3);
  float *br_interp = (float *) lua_touserdata(L, 4);
  int minRadius = luaL_checkint(L, 5);
  int cidx = luaL_checkint(L, 6);
  int nrows = luaL_checkint(L, 7);
  int ncols = luaL_checkint(L, 8);
 
  diff_img(dst, src, mask, br_interp, minRadius, cidx, nrows, ncols);

  return 1;
}

int lua_local_max2(lua_State *L) {
  float *dst = (float *) lua_touserdata(L, 1);
  float *src = (float *) lua_touserdata(L, 2);
  int widthFilter = luaL_checkint(L, 3);
  int localMaxThreshold = luaL_checkint(L, 4);
  int topMostRow = luaL_checkint(L, 5);
  int nrows = luaL_checkint(L, 6);
  int ncols = luaL_checkint(L, 7);
 
  local_max(dst, src, widthFilter, localMaxThreshold, topMostRow, 
            nrows, ncols);

  return 1;
}