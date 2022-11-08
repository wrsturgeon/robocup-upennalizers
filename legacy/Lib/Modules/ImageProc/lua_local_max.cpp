
#include "lua_local_max.h"

int lua_local_max(lua_State *L) {
	//if (not (luaT_isudata(L, 1, "torch.FloatTensor")
	//		and luaT_isudata(L, 2, "torch.FloatTensor")
	//		and lua_isnumber(L, 3)
	//		and lua_isnumber(L, 4)
	//		and lua_isnumber(L, 5)))
	//	return luaL_error(L, "Input invalid");

	if (not luaT_isudata(L, 1, "torch.FloatTensor"))
		return luaL_error(L, "c++: first input wrong");
	if (not luaT_isudata(L, 2, "torch.FloatTensor"))
		return luaL_error(L, "c++: second input wrong");
	if (not lua_isnumber(L, 3))
		return luaL_error(L, "c++: third input wrong");
	if (not lua_isnumber(L, 4))
		return luaL_error(L, "c++: fourth input wrong");
	if (not lua_isnumber(L, 5))
		return luaL_error(L, "c++: fifth input wrong");


	THFloatTensor *dst =
			(THFloatTensor *) luaT_checkudata(L, 1, "torch.FloatTensor");
	THFloatTensor *src =
			(THFloatTensor *) luaT_checkudata(L, 2, "torch.FloatTensor");
	int widthFilter = luaL_checkint(L, 3);
	int localMaxThreshold = luaL_checknumber(L, 4);
	int topMostRow = luaL_checkint(L, 5);
	
	src = THFloatTensor_newContiguous(src);

	float *d_i = THFloatTensor_data(dst);
	float *s_i = THFloatTensor_data(src);

	int nrows = src->size[0];
	int ncols = src->size[1];
	
	int dist = floor(widthFilter/2);
	float max;	

	//for (int i=0; i<topMostRow; i++) {
	//	for (int j=0; j<ncols; j++) {
	//		*(d_i + i*ncols + j) = *(s_i + i*ncols + j);
	//	}
	//}

	for (int i=topMostRow; i<nrows; i++) {
		for (int j=0; j<ncols; j++) {
			if (*(s_i + i*ncols + j) > 0) { // only do calculation if that value is high enough to be meaningful local max
				//std::vector<float> numsInFilter;
				max = 0;
				for (int x=std::max(0,i-dist); x<=std::min(i+dist, nrows-1); x++) {
					for (int y=std::max(0,j-dist); y<=std::min(j+dist, ncols-1); y++) {
						if (!( (x==i) && (y==j) )) {
							//numsInFilter.push_back(*(s_i + x*ncols + y));
							if (*(s_i + x*ncols + y) > max) {
								max = *(s_i + x*ncols + y);
							}
						}
					}
				}
				//*(d_i + i*ncols + j) = *std::max_element(numsInFilter.begin(), numsInFilter.end());
				*(d_i + i*ncols + j) = max;
			}
		}
	}

	THFloatTensor_free(src);

	return 1;
}
