
varying lowp vec4 v_color;

#ifdef VERTEX_SHADER

attribute vec4 position;
attribute vec4 color;

uniform float size;

void main()
{
	//OpenGL ES 2.0
	gl_Position = position;
	mediump float p = (0.5 + 0.5 * abs(position.y));
	gl_PointSize = size * p;
	v_color = color / p;
}

#endif



#ifdef FRAGMENT_SHADER

//Declare a 2D texture as a uniform variable
uniform sampler2D sTexture;

void main()
{
	gl_FragColor = v_color * texture2D(sTexture, gl_PointCoord);
}

#endif
