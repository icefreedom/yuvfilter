
static inline int pre_filter(int a, int b, int c)
{
	int ab = (a-b) >> 31;
	int bc = (b-c) >> 31;
	int ca = (c-a) >> 31;

	int ma = a & ~(ab^ca);
	int mb = b & (bc^~ab);
	int mc = c & ~(ca^bc);

	return ma | mb | mc;
}

static int xx_pre_filter_plane_c(uint8_t * dst, int dst_stride, uint8_t * src, int src_stride, int width, int height)
{
	int i, j;

	for (j = 0; j < 2; j++)
	{
		memcpy(dst + j*dst_stride, src + j*src_stride, width);
		memcpy(dst + (height-1-j)*dst_stride, src + (height-1-j)*src_stride, width);
	}

	for (j = 2; j < height-2; j++)
	{
		uint8_t * pdst = dst + j*dst_stride;
		uint8_t * psrc = src + j*src_stride;
		uint8_t * src0 = psrc - width;
		uint8_t * src1 = psrc;
		uint8_t * src2 = psrc + width;

		for (i = 0; i < width; i++)
		{
			int a = pre_filter(src0[i-1], src0[i], src0[i+1]);
			int b = pre_filter(src1[i-1], src1[i], src1[i+1]);
			int c = pre_filter(src2[i-1], src2[i], src2[i+1]);
			pdst[i] = pre_filter(a, b, c);
		}
	}

	return 0;
}

int xx_pre_filter_i420_c(uint8_t * dst[4], int dst_stride[4], uint8_t * src[4], int src_stride[4], int width, int height)
{
	xx_pre_filter_plane_c(dst[0], dst_stride[0], src[0], src_stride[0], width>>0, height>>0);
	xx_pre_filter_plane_c(dst[1], dst_stride[1], src[1], src_stride[1], width>>1, height>>1);
	xx_pre_filter_plane_c(dst[2], dst_stride[2], src[2], src_stride[2], width>>1, height>>1);
	return 0;
}