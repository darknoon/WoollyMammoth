
varying highp vec2 v_tc[3];

#ifdef VERTEX_SHADER

attribute vec4 position;
attribute vec2 texCoord0;

void main()
{
	//OpenGL ES 2.0
	gl_Position = position;
	
	highp vec2 off = vec2(0.0, 0.005 * position.y);
	
	v_tc[0] = texCoord0 - off;
	v_tc[1] = texCoord0;
	v_tc[2] = texCoord0 + off;
}

#endif



#ifdef FRAGMENT_SHADER

//Declare a 2D texture as a uniform variable
uniform sampler2D sTexture;

void main()
{
	lowp float r = texture2D(sTexture, v_tc[0]).r;
	lowp float g = texture2D(sTexture, v_tc[1]).r;
	lowp float b = texture2D(sTexture, v_tc[2]).r;
	
	gl_FragColor.rgb = 1.0 * vec3(r,g,b) - 0.05;
}

#endif
