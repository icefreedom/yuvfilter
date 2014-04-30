#ifndef _IMAGE_FILTER_H_
#define _IMAGE_FILTER_H_
#include <sys/types.h>
#ifdef __cplusplus
extern "C" {
#endif

int xx_pst_filter_plane_neon(uint8_t * dst, int dst_stride, uint8_t * src, int src_stride, int width, int height);

int xx_pst_filter_i420_c(uint8_t * dst[4], int dst_stride[4], uint8_t * src[4], int src_stride[4], int width, int height);
int xx_pst_filter_i420_neon(uint8_t * dst[4], int dst_stride[4], uint8_t * src[4], int src_stride[4], int width, int height);

#ifdef __cplusplus
}
#endif

#endif
