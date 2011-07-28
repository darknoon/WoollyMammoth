uniform sampler2D texture;
uniform lowp vec4 color;

varying highp vec2 v_textureCoordinate;

void main()
{
	gl_FragColor = color * texture2D(texture, v_textureCoordinate);
}
