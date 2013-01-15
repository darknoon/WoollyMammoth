attribute vec4 position;
attribute vec2 texCoord0;

uniform mat4 wm_T;

varying highp vec2 v_tc;

void main()
{
    gl_Position = wm_T * position;
	v_tc = texCoord0;
}
