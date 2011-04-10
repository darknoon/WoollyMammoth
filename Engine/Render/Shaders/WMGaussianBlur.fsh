uniform sampler2D texture;

//uniform float offset[3] = float[]( 0.0, 1.3846153846, 3.2307692308 );

varying highp vec4 vTexCoordPos;
varying highp vec3 vTexCoordNeg;

//TODO: use varying for all sample coordinates

void main(void)
{
	const mediump vec3 weight = vec3( 0.2270270270, 0.3162162162, 0.0702702703 );

	mediump vec4 fragmentColor =
	                 texture2D(texture, vTexCoordPos.xy) * weight.x;
	fragmentColor += texture2D(texture, vTexCoordPos.xz) * weight.y;
	fragmentColor += texture2D(texture, vTexCoordPos.xw) * weight.z;
	fragmentColor += texture2D(texture, vTexCoordNeg.xy) * weight.y;
	fragmentColor += texture2D(texture, vTexCoordNeg.xz) * weight.z;
	gl_FragColor = fragmentColor;
}
