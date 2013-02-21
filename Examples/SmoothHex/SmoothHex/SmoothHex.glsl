
varying highp vec2 v_tc[4];
varying highp vec2 v_center[4];

uniform lowp float r;

#ifdef VERTEX_SHADER

attribute vec2 p;
attribute vec2 c0;
attribute vec2 c1;
attribute vec2 c2;
attribute vec2 c3;

uniform lowp float influence;


//Get the final texture coord from the center and position
highp vec2 texCoord(vec2 ctr, vec2 pos) {
	vec2 imageRatio = vec2(320.0 / 568.0, 1.0);
	
	highp vec2 offset = (ctr - pos);
	highp vec2 pre =  0.5 + 0.2 * vec2(1.0 - pos.x, pos.y) + 0.6 * vec2(offset.x, -offset.y);
	return vec2(1.0 - imageRatio.x * pre.y, pre.x);
}

void main()
{
	gl_Position = vec4(2.0 * p.x - 1.0, 320.0 / 568.0 * 2.0 * p.y - 1.0, 0.0, 1.0);
	
	v_tc[0] = texCoord(c0, p);
	v_tc[1] = texCoord(c1, p);
	v_tc[2] = texCoord(c2, p);
	v_tc[3] = texCoord(c3, p);
	
	v_center[0] = c0 - p;
	v_center[1] = c1 - p;
	v_center[2] = c2 - p;
	v_center[3] = c3 - p;
}

#endif



#ifdef FRAGMENT_SHADER

//Declare a 2D texture as a uniform variable
uniform sampler2D texture;

void main()
{
	lowp vec3 c0 = texture2D(texture, v_tc[0]).rgb;
	lowp vec3 c1 = texture2D(texture, v_tc[1]).rgb;
	lowp vec3 c2 = texture2D(texture, v_tc[2]).rgb;
	lowp vec3 c3 = texture2D(texture, v_tc[3]).rgb;
	
	lowp float kmax = 2.4;
	lowp float kmin = 1.9;
	
	//Weight each by distance to the center
	lowp float k0 = clamp(kmax - kmin * length(v_center[0]) / r, 0.0, 1.0);
	lowp float k1 = clamp(kmax - kmin * length(v_center[1]) / r, 0.0, 1.0);
	lowp float k2 = clamp(kmax - kmin * length(v_center[2]) / r, 0.0, 1.0);
	lowp float k3 = clamp(kmax - kmin * length(v_center[3]) / r, 0.0, 1.0);
	
	lowp float fixOverlap = k0 + k1 + k2 + k3;
	
	lowp vec3 color = 1.1 / fixOverlap * (k0*c0 + k1*c1 + k2*c2 + k3*c3) - 0.1;
	gl_FragColor.rgb = color;
}

#endif
