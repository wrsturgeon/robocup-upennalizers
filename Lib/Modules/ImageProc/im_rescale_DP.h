#ifndef im_rescale_DP_h_DEFINED
#define im_rescale_DP_h_DEFINED

#include <iostream>
#include <stdint.h>

int im_rescale_idx(long *idx_src, long *idx_dst, float *idx_s2d, long *idx_left,
                   float Ks, float Kd);

int bilinear_interp (float *img_src, float *img_dst, float *idx_s2d, long *idx_left,
                     int Ks, int Kd);

#endif