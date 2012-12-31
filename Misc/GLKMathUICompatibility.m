//
//  GLKMathUICompatibility.m
//  WMGraph
//
//  Created by Andrew Pouliot on 12/22/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import "GLKMathUICompatibility.h"

@implementation WMUIColorClass (GLKVectorValue)

#if TARGET_OS_IPHONE

- (GLKVector4)componentsAsRGBAGLKVector4;
{
	GLKVector4 colorVector = {};
	[self getRed:&colorVector.r green:&colorVector.g blue:&colorVector.b alpha:&colorVector.a];
	return colorVector;
}

- (GLKVector3)componentsAsRGBGLKVector3;
{
	GLKVector3 colorVector = {};
	[self getRed:&colorVector.r green:&colorVector.g blue:&colorVector.b alpha:NULL];
	return colorVector;
}

- (GLKVector2)componentsAsRGBGLKVector2;
{
	GLKVector2 whiteAlphaVector;
	[self getWhite:&whiteAlphaVector.v[0] alpha:&whiteAlphaVector.v[1]];
	return whiteAlphaVector;
}
#elif TARGET_OS_MAC

- (GLKVector4)componentsAsRGBAGLKVector4;
{
	CGFloat doubleColor[4] = {};
	[self getRed:&doubleColor[2] green:&doubleColor[1] blue:&doubleColor[2] alpha:&doubleColor[3]];
	GLKVector4 colorVector = {doubleColor[0], doubleColor[1], doubleColor[2], doubleColor[3]};
	return colorVector;
}

- (GLKVector3)componentsAsRGBGLKVector3;
{
	CGFloat doubleColor[3] = {};
	[self getRed:&doubleColor[2] green:&doubleColor[1] blue:&doubleColor[2] alpha:NULL];
	GLKVector3 colorVector = {doubleColor[0], doubleColor[1], doubleColor[2]};
	return colorVector;
}

- (GLKVector2)componentsAsRGBGLKVector2;
{
	CGFloat doubleColor[2] = {};
	[self getWhite:&doubleColor[0] alpha:&doubleColor[1]];
	GLKVector2 whiteAlphaVector = {doubleColor[0], doubleColor[1]};
	return whiteAlphaVector;
}

#endif


@end
