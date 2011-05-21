//Calculate these once in the vertex shader then pass to fragment shader
varying mediump vec2 vTexCoord0;
varying mediump vec2 vTexCoord1;
varying mediump vec2 vTexCoord2;

#ifdef VERTEX_SHADER

#ifdef TARGET_OS_IPHONE
attribute vec4 position;
attribute vec2 texCoord0;
#endif

uniform vec2 offset;

void main()
{
#ifdef TARGET_OS_IPHONE
	//OpenGL ES 2.0
	gl_Position = position;
#else
	//OpenGL 2.0
	gl_Position = gl_Vertex;
	vec2 texCoord0 = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
#endif

	// Calculate texture offsets and pass through	
	
	vTexCoord0 = texCoord0 - offset;
	vTexCoord1 = texCoord0;
	vTexCoord2 = texCoord0 + offset;    
}

#endif

#ifdef FRAGMENT_SHADER

//Declare a 2D texture as a uniform variable
uniform sampler2D sTexture;

void main()
{
	lowp vec3 color = texture2D(sTexture, vTexCoord0).rgb * 0.333333;
	  color = color + texture2D(sTexture, vTexCoord1).rgb * 0.333333;
	  color = color + texture2D(sTexture, vTexCoord2).rgb * 0.333333;
	
	  gl_FragColor.rgb = color;
}

#endif
