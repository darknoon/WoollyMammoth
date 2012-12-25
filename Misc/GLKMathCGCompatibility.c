//
//  GLKVectorCGCompatibility.c
//  PopVideo
//
//  Created by Andrew Pouliot on 7/26/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import "GLKMathCGCompatibility.h"

GLKVector4 CGColorGetComponentsAsGLKVector4(CGColorRef c) {
	const CGFloat *colorComponents = CGColorGetComponents(c);
	size_t componentCount = CGColorGetNumberOfComponents(c);
	if (componentCount == 4) {
		return (GLKVector4){colorComponents[0], colorComponents[1], colorComponents[2], colorComponents[3]};
	} else {
		return (GLKVector4){};
	}
}