
#include "lua_diff_img.h"

int lua_diff_img(lua_State *L) {
	if (not (luaT_isudata(L, 1, "torch.FloatTensor")
			and luaT_isudata(L, 2, "torch.FloatTensor")
			and luaT_isudata(L, 3, "torch.ByteTensor")
			and luaT_isudata(L, 4, "torch.FloatTensor")
			and lua_isnumber(L, 5)
			and lua_isnumber(L, 6)))
		return luaL_error(L, "Input invalid");

	THFloatTensor *dst =
			(THFloatTensor *) luaT_checkudata(L, 1, "torch.FloatTensor");
	THFloatTensor *src =
			(THFloatTensor *) luaT_checkudata(L, 2, "torch.FloatTensor");
	THByteTensor *mask =
			(THByteTensor *) luaT_checkudata(L, 3, "torch.ByteTensor");
	THFloatTensor *ball_radius = 
			(THFloatTensor *) luaT_checkudata(L, 4, "torch.FloatTensor");
	int minRadius = luaL_checkint(L, 5);
	int cidx = luaL_checkint(L, 6);

	src = THFloatTensor_newContiguous(src);
	mask = THByteTensor_newContiguous(mask);
	ball_radius = THFloatTensor_newContiguous(ball_radius);
	float *d_i = THFloatTensor_data(dst);
	float *s_i = THFloatTensor_data(src);
	unsigned char *mask_i = THByteTensor_data(mask);
	float *br_i = THFloatTensor_data(ball_radius);


	int nrows = src->size[0];
	int ncols = src->size[1];

	int width; // this needs to be adjusted in the future
	int extra_width;
	if (cidx == 1)
		extra_width = 6; // 10
	else if (cidx == 2)
		extra_width = 3; // 5

	int l1, l2;

	int x_idx_left_top;
	int y_idx_left_top;
	int x_idx_right_bottom;
	int y_idx_right_bottom;

	int x_idx_left_top_outside;
	int y_idx_left_top_outside;
	int x_idx_right_bottom_outside;
	int y_idx_right_bottom_outside;

	float *left_top;
	float *right_top;
	float *left_bottom;
	float *right_bottom;

	float *left_top_outside;
	float *right_top_outside;
	float *left_bottom_outside;
	float *right_bottom_outside;

	float inside_sum;
	float outside_sum;
	float normalizer1, normalizer2;

	for (int i=0; i<nrows; i++) {
		width = *(br_i + i);
		if (width >= minRadius) {
			for (int j=0; j<ncols; j++) {
				if (*(mask_i + i*ncols + j) ==1) {
					x_idx_left_top = std::max(0, i-width);
					y_idx_left_top = std::max(0, j-width);
					x_idx_right_bottom = std::min(nrows-1, i+width);
					y_idx_right_bottom = std::min(ncols-1, j+width);

					x_idx_left_top_outside = std::max(0, i-width-extra_width);
					y_idx_left_top_outside = std::max(0, j-width-extra_width);
					x_idx_right_bottom_outside = std::min(nrows-1, i+width+extra_width);
					y_idx_right_bottom_outside = std::min(ncols-1, j+width+extra_width);

					left_top = s_i + x_idx_left_top * ncols + y_idx_left_top;
					right_top = s_i + x_idx_left_top * ncols + y_idx_right_bottom;
					left_bottom = s_i + x_idx_right_bottom * ncols + y_idx_left_top;
					right_bottom = s_i + x_idx_right_bottom * ncols + y_idx_right_bottom; 

					left_top_outside = s_i + x_idx_left_top_outside * ncols + y_idx_left_top_outside;
					right_top_outside = s_i + x_idx_left_top_outside * ncols + y_idx_right_bottom_outside;
					left_bottom_outside = s_i + x_idx_right_bottom_outside * ncols + y_idx_left_top_outside;
					right_bottom_outside = s_i + x_idx_right_bottom_outside * ncols + y_idx_right_bottom_outside; 

					inside_sum = *right_bottom - *left_bottom - *right_top + *left_top;
					outside_sum = *right_bottom_outside - *left_bottom_outside - *right_top_outside + *left_top_outside;

					//normalizer = (3*width*width) - ((width+extra_width)*(width+extra_width));
					l1 = (x_idx_right_bottom-x_idx_left_top+1)
								* (y_idx_right_bottom-y_idx_left_top+1);
					l2 = (x_idx_right_bottom_outside-x_idx_left_top_outside+1)
								* (y_idx_right_bottom_outside-y_idx_left_top_outside+1);
					normalizer1 = l1;
					normalizer2 = l2-l1;

					if (cidx == 1) {
						*(d_i + i*ncols + j) = 0.2*(inside_sum / normalizer1) 
																	+0.8*(inside_sum / normalizer1 - 
																				(outside_sum-inside_sum)/normalizer2);
					} else if (cidx == 2) {
						*(d_i + i*ncols + j) = 0.2*(inside_sum / normalizer1) 
																	+0.8*(inside_sum / normalizer1 - 
																				(outside_sum-inside_sum)/normalizer2);
					}
				}
			}
		}
	}

	THFloatTensor_free(src);
	THByteTensor_free(mask);
	THFloatTensor_free(ball_radius);

	return 1;
}
