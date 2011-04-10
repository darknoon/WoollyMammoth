//
//  Shader.vsh
//  CaptureTest
//
//  Created by Andrew Pouliot on 8/12/10.
//  Copyright Darknoon 2010. All rights reserved.
//

attribute vec4 position;
attribute vec2 texCoord0;

uniform float invStepWidth1; // 1.3846153846 / texHeight
uniform float invStepWidth2; // 3.2307692308 / texHeight

varying highp vec4 vTexCoordPos;
varying highp vec3 vTexCoordNeg;

void main()
{
    gl_Position = position;
	//Calculate the texture bits to send to the card
	vTexCoordPos = vec4(texCoord0.x, texCoord0.y                , texCoord0.y + invStepWidth1, texCoord0.y + invStepWidth2);
	vTexCoordNeg = vec3(texCoord0.x, texCoord0.y - invStepWidth1, texCoord0.y - invStepWidth2);
}
