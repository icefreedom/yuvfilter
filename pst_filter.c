//extern int xx_pst_filter_plane_neon(uint8_t * dst, int dst_stride, uint8_t * src, int src_stride, int width, int height);
#include "pst_filter.h"
#include <sys/types.h>
static inline uint8_t clip_uint8( int a )
{
	if (a&(~255))
		return (uint8_t)((-a)>>31);
	else
		return (uint8_t)a;
}

static int xx_pst_filter_plane_c(uint8_t * dst, int dst_stride, uint8_t * src, int src_stride, int width, int height)
{
	int i, j;

	for (j = 0; j < height-0; j++)
	{
		uint8_t * pdst = dst + j*dst_stride;
		uint8_t * psrc = src + j*src_stride;
		uint8_t * src0 = psrc - src_stride;
		uint8_t * src1 = psrc;
		uint8_t * src2 = psrc + src_stride;

		for (i = 0; i < width; i++)
		{
			int x1 = src0[i-1] + src0[i+1] + src2[i-1] + src2[i+1];
			int x2 = src0[i] + src1[i-1] + src1[i+1] + src2[i];
			int x4 = src1[i];

			int delta = (x1 + (x2<<2) - (x4*20) + 8) >> 4;

			int t = psrc[i] - delta;

			pdst[i] = clip_uint8(t);
		}
	}

	return 0;
}

static int xx_pst_filter_plane_ver_c(uint8_t * dst, int dst_stride, uint8_t * src, int src_stride, int width, int height)
{
	int i, j;

	for (j = 0; j < 2; j++)
	{
		memcpy(dst + j*dst_stride, src + j*src_stride, width);
		memcpy(dst + (height-1-j)*dst_stride, src + (height-1-j)*src_stride, width);
	}

	xx_pst_filter_plane_c(dst + 2*dst_stride, dst_stride, src + 2*src_stride, src_stride, width, height-4);

	return 0;
}

static int xx_pst_filter_plane_ver_neon(uint8_t * dst, int dst_stride, uint8_t * src, int src_stride, int width, int height)
{
	int i, j;

	for (j = 0; j < 2; j++)
	{
		memcpy(dst + j*dst_stride, src + j*src_stride, width);
		memcpy(dst + (height-1-j)*dst_stride, src + (height-1-j)*src_stride, width);
	}

	xx_pst_filter_plane_neon(dst + 2*dst_stride, dst_stride, src + 2*src_stride, src_stride, width, height-4);

	return 0;
}

int xx_pst_filter_i420_c(uint8_t * dst[4], int dst_stride[4], uint8_t * src[4], int src_stride[4], int width, int height)
{
	xx_pst_filter_plane_ver_c(dst[0], dst_stride[0], src[0], src_stride[0], width>>0, height>>0);
	xx_pst_filter_plane_ver_c(dst[1], dst_stride[1], src[1], src_stride[1], width>>1, height>>1);
	xx_pst_filter_plane_ver_c(dst[2], dst_stride[2], src[2], src_stride[2], width>>1, height>>1);
	return 0;
}
int xx_pst_filter_i420_neon(uint8_t * dst[4], int dst_stride[4], uint8_t * src[4], int src_stride[4], int width, int height)
{
	xx_pst_filter_plane_ver_neon(dst[0], dst_stride[0], src[0], src_stride[0], width>>0, height>>0);
	xx_pst_filter_plane_ver_neon(dst[1], dst_stride[1], src[1], src_stride[1], width>>1, height>>1);
	xx_pst_filter_plane_ver_neon(dst[2], dst_stride[2], src[2], src_stride[2], width>>1, height>>1);
	return 0;
}
