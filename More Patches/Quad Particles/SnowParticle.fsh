//
//  Shader.fsh
//  Snow Globe
//
//  Created by Andrew Pouliot on 9/27/10.
//  Copyright Darknoon 2010. All rights reserved.
//

uniform sampler2D texture;

varying lowp vec4 v_color;
varying mediump vec2 v_tc;

void main()
{
	gl_FragColor = texture2D(texture, v_tc) * v_color;
}
