#ifndef region_proposal_h_DEFINED
#define region_proposal_h_DEFINED

#include <iostream>
#include <stdint.h>
#include <math.h>

int integral_image(float *d_i, float *s_i, int nrows, int ncols, int stride);

int high_contrast_parts(uint8_t *dst_i, float *y_i, float *y_intImg_i,
	                    float *br_i, int minRadius, int width, int cidx,
	                    int nrows, int ncols);

int top_most_row(float *s_i, int nrows, int ncols);

int diff_img(float *d_i, float *s_i, uint8_t *mask_i, float *br_i,
	         int minRadius, int cidx, int nrows, int ncols);

int local_max(float *d_i, float *s_i, int widthFilter,
	              int localMaxThreshold, int topMostRow,
	              int nrows, int ncols);

#endif