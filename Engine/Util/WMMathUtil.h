#ifdef __cplusplus
extern "C" {
#endif
#include "stdlib.h"

	//via http://graphics.stanford.edu/~seander/bithacks.html#RoundUpPowerOf2Float
	
	static inline unsigned int nextPowerOf2(unsigned int v) {
		v--;
		v |= v >> 1;
		v |= v >> 2;
		v |= v >> 4;
		v |= v >> 8;
		v |= v >> 16;
		return v+1;
	};
	
#if 1
	//via http://iquilezles.org/www/articles/sfrand/sfrand.htm
	static inline float randF(int *inOutSeed) {
		float res;
		inOutSeed[0] *= 16807;
		*((unsigned int *) &res) = ( ((unsigned int)inOutSeed[0])>>9 ) | 0x40000000;
		return res - 3.0f;
	}
#endif

	static inline float randFR(int *inOutSeed, float min, float max) {
		return min + (max - min) * randF(inOutSeed);
	}

#ifdef __cplusplus
}
#endif