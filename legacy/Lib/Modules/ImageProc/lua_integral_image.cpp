
#include "lua_integral_image.h"

// implementation of torch-saliency library by macroscoffier
// for single channel integral image of ByteTensor input

int lua_integral_image(lua_State *L) {
	if (not (luaT_isudata(L, 1, "torch.FloatTensor") 
				and luaT_isudata(L, 2, "torch.FloatTensor"))) {
		return luaL_error(L, "Inputs invalid");
	}
	
	THFloatTensor *dst = // dst for destination
			(THFloatTensor *) luaT_checkudata(L, 1, "torch.FloatTensor");
	THFloatTensor *src = // src for source
			(THFloatTensor *) luaT_checkudata(L, 2, "torch.FloatTensor");

	src = THFloatTensor_newContiguous(src);
	int ir = src->size[0]; // input rows
	int ic = src->size[1]; // input cols
	int sch = src->stride[0];

	THFloatTensor_resize2d(dst, ir, ic);

	float *d_i = THFloatTensor_data(dst);
	float *s_i = THFloatTensor_data(src);

	float *d_ip, *d_io; // d_ip = d_i_previous
	float d_ow;
	int xx, yy;

	d_io = d_i;

	*d_i = *s_i; // value of first d_i is set to value of first s_i
	d_ip = d_i; // moving onto other rows/cols, so save d_i's location as d_ip
	d_i++; s_i++; // move pointer to next element (same col, moving in row direction?)

	// do first col
	for (xx=1; xx<ic; xx++) {
		*d_i = *s_i + *d_ip;
		d_i++; s_i++; d_ip++;
	}

	// now "d_ip" tracks pointer in previous col
	d_ip = d_io;
	d_io += sch;
	for (yy=1; yy<ir; yy++) {
		// copy first element in row
		d_ow = 0; // row tracks to the left
		for (xx=0; xx<ic; xx++) {
			d_ow += *s_i;
			*d_i = d_ow + *d_ip;
			d_i++; s_i++; d_ip++;
		}
	}

	// cleanup
	THFloatTensor_free(src); // in torch7/lib/TH/generic/THTensor.c in original library
	
	return 1;
}

