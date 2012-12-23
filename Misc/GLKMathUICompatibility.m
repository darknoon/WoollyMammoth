//
//  GLKMathUICompatibility.m
//  WMGraph
//
//  Created by Andrew Pouliot on 12/22/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import "GLKMathUICompatibility.h"


@implementation UIColor (GLKVectorValue)

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

@end
