//
//  GLKVectorCGCompatibility.c
//  PopVideo
//
//  Created by Andrew Pouliot on 7/26/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import "GLKMathCGCompatibility.h"

GLKVector4 CGColorGetComponentsAsGLKVector4(CGColorRef c) {
	GLKVector4 v;
	v.v = CGColorGetComponents(c);
}