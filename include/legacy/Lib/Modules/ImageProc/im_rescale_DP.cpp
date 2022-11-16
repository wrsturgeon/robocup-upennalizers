
#include "im_rescale_DP.h"

int im_rescale_idx(long *idx_src, long *idx_dst, float *idx_s2d, long *idx_left,
                   float Ks, float Kd) {

  if (Ks > Kd) {
    float inc = (Kd-1)/(Ks-1);

    int count = 0;
    for (int i=0; i<Ks; i++) {
      if ((*(idx_dst+count) - *(idx_s2d+i)) < inc) {
        *(idx_left+count) = *(idx_src+i);
        count++;
      }
      if (count >= Kd) {
        break;
      }
    }
  }
  else if (Ks < Kd) {
    int count = 0;
    for (int i=0; i<Kd; i++) {
      if (*(idx_s2d+i) < *(idx_src+count+1)) {
        *(idx_left+i) = *(idx_src+count);
      } else {
        *(idx_left+i) = *(idx_src+count+1);
        count++;
      }
      if (count >= Ks) {
        break;
      }
    }
  }
  else {
    std::cout << "same Ks and Kd" << std::endl;
  }

  return 1;
}

int bilinear_interp (float *img_src, float *img_dst, float *idx_s2d, long *idx_left,
                     int Ks, int Kd) {

  int idx_left_top;
  int idx_right_top;
  int idx_left_bot;
  int idx_right_bot;

  float f11; // pixel value at left top of desired pixel
  float f12; // pixel value at right top of desired pixel
  float f21; // pixel value at left bot of desired pixel
  float f22; // pixel value at right bot of desired pixel
  float fxy1; // intermediate value for bilinear interpolation
  float fxy2; // intermediate value for bilinear interpolation

  float x;
  float y;
  float x1;
  float x2;
  float y1;
  float y2;
  
  float x_den;
  float y_den;

  if (Ks > Kd) { 
    for (int i=0; i<Kd; i++) { // row of img_dst
      for (int j=0; j<Kd; j++) { // col of img_dst
        x = j+1; // j is column index, so x direction
        y = i+1; // i is row index, so y direction
 
        idx_left_top = (*(idx_left+i)-1)*Ks + *(idx_left+j) - 1;
        idx_right_top = (*(idx_left+i)-1)*Ks + *(idx_left+j);
        idx_left_bot = (*(idx_left+i))*Ks + *(idx_left+j) - 1;
        idx_right_bot = (*(idx_left+i))*Ks + *(idx_left+j);
  
        // based on Wikipedia convention ('bilinear interpolation')
        x1 = *(idx_s2d + *(idx_left + j)-1); // left
        y2 = *(idx_s2d + *(idx_left + i)-1); // top
        
        if (*(idx_left + j) < Ks) {
          x2 = *(idx_s2d + *(idx_left + j)); // right
        } else {
          x2 = x;
        }
        
        if (*(idx_left + i) < Ks) {
          y1 = *(idx_s2d + *(idx_left + i)); // bot
        } else {
          y1 = y;
        }

        if ((x2 < Kd) && (y1 < Kd)) {
          f12 = *(img_src + idx_left_top);
          f11 = *(img_src + idx_left_bot);
          f22 = *(img_src + idx_right_top);
          f21 = *(img_src + idx_right_bot);
        } else if (x2 < Kd){
          f12 = *(img_src + idx_left_top);
          f11 = 0;
          f22 = *(img_src + idx_right_top);
          f21 = 0;
        } else if (y1 < Kd) {
          f12 = *(img_src + idx_left_top);
          f11 = *(img_src + idx_left_bot);
          f22 = 0;
          f21 = 0;
        } else {
          f12 = *(img_src + idx_left_top);
          f11 = 0;
          f22 = 0;
          f21 = 0;
        }
 
        if ((x1 == x2) || (y1 == y2)) {
          x_den = 1;
          y_den = 1;
        } else {
          x_den = x2-x1;
          y_den = y2-y1;
        }
        fxy1 = (x2-x)/x_den * f11 + (x-x1)/x_den * f21;
        fxy2 = (x2-x)/x_den * f12 + (x-x1)/x_den * f22;
  
//        std::cout << i << ", " << j << ", " << *(img_dst + i*Kd + j) << std::endl;

        *(img_dst + i*Kd + j) = (y2-y)/y_den * fxy1 + (y-y1)/y_den * fxy2;
      }
    }
  }
  else if (Ks < Kd) {
    for (int i=0; i<Kd; i++) { // row of img_dst
      for (int j=0; j<Kd; j++) { // col of img_dst
        idx_left_top = (*(idx_left+i)-1)*Ks + *(idx_left+j) - 1;
        idx_right_top = (*(idx_left+i)-1)*Ks + *(idx_left+j);
        idx_left_bot = (*(idx_left+i))*Ks + *(idx_left+j) - 1;
        idx_right_bot = (*(idx_left+i))*Ks + *(idx_left+j);
  
        x = *(idx_s2d + j)-1; // j is column index, so x direction
        y = *(idx_s2d + i)-1; // i is row index, so y direction

        // based on Wikipedia convention ('bilinear interpolation')
        x1 = *(idx_left + j)-1; // left
        x2 = *(idx_left + j); // right
        y2 = *(idx_left + i)-1; // top
        y1 = *(idx_left + i); // bot

        if ((x2 < Ks) && (y1 < Ks)) {
          f12 = *(img_src + idx_left_top);
          f11 = *(img_src + idx_left_bot);
          f22 = *(img_src + idx_right_top);
          f21 = *(img_src + idx_right_bot);
        } else if (x2 < Ks){
          f12 = *(img_src + idx_left_top);
          f11 = 0;
          f22 = *(img_src + idx_right_top);
          f21 = 0;
        } else if (y1 < Ks) {
          f12 = *(img_src + idx_left_top);
          f11 = *(img_src + idx_left_bot);
          f22 = 0;
          f21 = 0;
        } else {
          f12 = *(img_src + idx_left_top);
          f11 = 0;
          f22 = 0;
          f21 = 0;
        }

        //  std::cout << "(" << x1 << ", " << y2 << ")   " << "(" << x2 << ", " << y1 << ")" << std::endl;
        //  std::cout << f12 << ", " << f22 << ", " << f11 << ", " << f21 << std::endl;
        //  std::cout << (x2-x)/(x2-x1) * f11 << ", " << (x-x1)/(x2-x1) * f21 << std::endl;
  
        fxy1 = (x2-x)/(x2-x1) * f11 + (x-x1)/(x2-x1) * f21;
        fxy2 = (x2-x)/(x2-x1) * f12 + (x-x1)/(x2-x1) * f22;
  
        *(img_dst + i*Kd + j) = (y2-y)/(y2-y1) * fxy1 + (y-y1)/(y2-y1) * fxy2;
      }
    }
  } else {
    std::cout << "Ks = Kd, shouldn't be in here" << std::endl;
  }

  
  return 1;
}
