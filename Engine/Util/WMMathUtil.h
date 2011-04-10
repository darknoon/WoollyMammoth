#ifdef __cplusplus
extern "C" {
#endif

	//via http://graphics.stanford.edu/~seander/bithacks.html#RoundUpPowerOf2Float
	
	inline unsigned int nextPowerOf2(unsigned int v) {
		v--;
		v |= v >> 1;
		v |= v >> 2;
		v |= v >> 4;
		v |= v >> 8;
		v |= v >> 16;
		return v+1;
	};
		
#ifdef __cplusplus
}
#endif