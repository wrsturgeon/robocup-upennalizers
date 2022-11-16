
#include "lua_high_contrast_parts.h"

int lua_high_contrast_parts(lua_State *L) {
	if (not (luaT_isudata(L, 1, "torch.ByteTensor")
			and luaT_isudata(L, 2, "torch.FloatTensor")
			and luaT_isudata(L, 3, "torch.FloatTensor")
			and luaT_isudata(L, 4, "torch.FloatTensor")
			and lua_isnumber(L, 5)
			and lua_isnumber(L, 6)
			and lua_isnumber(L, 7)))
		return luaL_error(L, "Input invalid");

	THByteTensor *dst =
			(THByteTensor *) luaT_checkudata(L, 1, "torch.ByteTensor");
	THFloatTensor *y =
			(THFloatTensor *) luaT_checkudata(L, 2, "torch.FloatTensor");
	THFloatTensor *y_intImg =
			(THFloatTensor *) luaT_checkudata(L, 3, "torch.FloatTensor");
	THFloatTensor *ball_radius = 
			(THFloatTensor *) luaT_checkudata(L, 4, "torch.FloatTensor");
	int minRadius = luaL_checkint(L, 5);
	int width = luaL_checkint(L, 6);
	int cidx = luaL_checkint(L, 7);

	y = THFloatTensor_newContiguous(y);
	y_intImg = THFloatTensor_newContiguous(y_intImg);
	ball_radius = THFloatTensor_newContiguous(ball_radius);

	unsigned char *dst_i = THByteTensor_data(dst);
	float *y_i = THFloatTensor_data(y);
	float *y_intImg_i = THFloatTensor_data(y_intImg);
	float *br_i = THFloatTensor_data(ball_radius);

	int nrows = dst->size[0];
	int ncols = dst->size[1];

	float sumWindow, meanWindow, accum, diffMean, stderrWindow;

	int x_idx_left_top;
	int y_idx_left_top;
	int x_idx_right_bottom;
	int y_idx_right_bottom;

	float *left_top;
	float *right_top;
	float *left_bottom;
	float *right_bottom;

	//int width;
	//if (cidx == 1)
	//	width = 15;
	//else if (cidx == 2)
	//	width = 13;

	float ballRadius;

	for (int i=0; i<=nrows-width-1; i=i+width+1) {
		ballRadius = *(br_i + i);
		if (ballRadius >= minRadius) {
			for (int j=0; j<=ncols-width-1; j=j+width+1) {
				// std::cout << '(' << i << ',' << j <<')' << std::endl;
				x_idx_left_top = i;
				y_idx_left_top = j;
				x_idx_right_bottom = x_idx_left_top + width;
				y_idx_right_bottom = y_idx_left_top + width;

				left_top = y_intImg_i + x_idx_left_top * ncols + y_idx_left_top;
				right_top = y_intImg_i + x_idx_left_top * ncols + y_idx_right_bottom;
				left_bottom = y_intImg_i + x_idx_right_bottom * ncols + y_idx_left_top;
				right_bottom = y_intImg_i + x_idx_right_bottom * ncols + y_idx_right_bottom;

				sumWindow = *right_bottom - *left_bottom - *right_top + *left_top;
				meanWindow = sumWindow/(width*width);

				accum=0;

				for (int ii=x_idx_left_top; ii<=x_idx_right_bottom; ii++) {
					for (int jj=y_idx_left_top; jj<=y_idx_right_bottom; jj++) {
						diffMean = *(y_i + ii * ncols + jj)-meanWindow;
						accum += diffMean*diffMean;
					}
				}

				stderrWindow = accum/((width+1)*(width+1)-1);

				if (stderrWindow > 25) {
					for (int ii=x_idx_left_top; ii<=x_idx_right_bottom; ii++) {
						for (int jj=y_idx_left_top; jj<=y_idx_right_bottom; jj++) {
							*(dst_i + ii * ncols + jj) = 1;
						}
					}
				}
			}
		}
	}

	THFloatTensor_free(y);
	THFloatTensor_free(y_intImg);
	THFloatTensor_free(ball_radius);

	return 1;
}
