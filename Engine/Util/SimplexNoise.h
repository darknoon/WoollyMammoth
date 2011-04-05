/*
 *  SimplexNoise.h
 *  ImageBlur
 *
 * Converted from Java: http://staffwww.itn.liu.se/~stegu/simplexnoise/simplexnoise.pdf
 */

typedef float SNFloat;


SNFloat simplexNoise2(SNFloat xin, SNFloat yin);
SNFloat simplexNoise3(SNFloat xin, SNFloat yin, SNFloat zin);

//From Inigo Quilez: this rulezz
//Get a vec3 derivative for a point instead of a constant
void dnoise3f(float *vout, const float x, const float y, const float z);
