
#include "lua_top_most_row.h"

int lua_top_most_row(lua_State *L) {
	if (not luaT_isudata(L, 1, "torch.FloatTensor"))
		return luaL_error(L, "Input invalid");

	THFloatTensor *src =
				(THFloatTensor *) luaT_checkudata(L, 1, "torch.FloatTensor");

	src = THFloatTensor_newContiguous(src);
	float *s_i = THFloatTensor_data(src);

	int nrows = src->size[0];
	int ncols = src->size[1];

	bool toBreak = false;
	bool loopedThrough = true;
	int topMostRow;

	for (int i=0; i<nrows; i++) {
		for(int j=0; j<ncols; j++) {
			if (*(s_i + i*ncols + j) !=0 ) {
				topMostRow = i; 
				toBreak = true;
				loopedThrough = false;
				lua_pushnumber(L, topMostRow);
			}
			if (toBreak)
				break;
		}
		if (toBreak)
			break;
	}

	if (loopedThrough)
		lua_pushnumber(L, 0);

	THFloatTensor_free(src);

	return 1;
}
