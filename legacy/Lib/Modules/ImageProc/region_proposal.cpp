#include "region_proposal.h"

int integral_image(float *d_i, float *s_i, int nrows, int ncols, int stride) {
	float *d_ip, *d_io; // d_ip = d_i_previous
	float d_ow;
	int xx, yy;

	d_io = d_i;

	*d_i = *s_i; // value of first d_i is set to value of first s_i
	d_ip = d_i; // moving onto other rows/cols, so save d_i's location as d_ip
	d_i++; s_i++; // move pointer to next element (same col, moving in row direction?)

	// do first col
	for (xx=1; xx<ncols; xx++) {
		*d_i = *s_i + *d_ip;
		d_i++; s_i++; d_ip++;
	}

	// now "d_ip" tracks pointer in previous col
	d_ip = d_io;
	d_io += stride;
	for (yy=1; yy<nrows; yy++) {
		// copy first element in row
		d_ow = 0; // row tracks to the left
		for (xx=0; xx<ncols; xx++) {
			d_ow += *s_i;
			*d_i = d_ow + *d_ip;
			d_i++; s_i++; d_ip++;
		}
	}

	return 1;
}

int high_contrast_parts(uint8_t *dst_i, float *y_i, float *y_intImg_i,
	                    float *br_i, int minRadius, int width, int cidx,
	                    int nrows, int ncols) {

	float sumWindow, meanWindow, accum, diffMean, stderrWindow;

	int x_idx_left_top;
	int y_idx_left_top;
	int x_idx_right_bottom;
	int y_idx_right_bottom;

	float *left_top;
	float *right_top;
	float *left_bottom;
	float *right_bottom;

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

	return 1;
}

int top_most_row(float *s_i, int nrows, int ncols) {
	bool toBreak = false;
	bool loopedThrough = true;
	int topMostRow;

	for (int i=0; i<nrows; i++) {
		for(int j=0; j<ncols; j++) {
			if (*(s_i + i*ncols + j) != 0 ) {
				topMostRow = i+1; 
				toBreak = true;
				loopedThrough = false;
				return topMostRow;
			}
			if (toBreak)
				break;
		}
		if (toBreak)
			break;
	}

	if (loopedThrough)
		return 0;
}

int diff_img(float *d_i, float *s_i, uint8_t *mask_i, float *br_i,
	         int minRadius, int cidx, int nrows, int ncols) {
	
	int width;
    int left_bound;
    int right_bound;
	int extra_width; // put this in as argument?
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
      left_bound = width - 1;
      right_bound = ncols - width;
			for (int j=left_bound; j<right_bound; j++) { // prevent bbox from going outside img boundary
				if (*(mask_i + i*ncols + j) == 1) {
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

	return 1;
}

int local_max(float *d_i, float *s_i, int widthFilter,
	              int localMaxThreshold, int topMostRow,
	              int nrows, int ncols) {	
	
	int dist = floor(widthFilter/2);
	float max;

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

	return 1;
}