//
//  Shader.fsh
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 9/27/10.
//  Copyright Darknoon 2010. All rights reserved.
//

uniform sampler2D texture;

varying highp vec2 v_textureCoordinate;

void main()
{
    gl_FragColor = texture2D(texture, v_textureCoordinate);
}
