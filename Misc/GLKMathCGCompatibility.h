//
//  GLKVectorCGCompatibility.h
//  PopVideo
//
//  Created by Andrew Pouliot on 7/26/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#ifndef PopVideo_GLKVectorCGCompatibility_h
#define PopVideo_GLKVectorCGCompatibility_h

#import <GLKit/GLKMath.h>
#import <CoreGraphics/CoreGraphics.h>

//GLKVec* to CGPoint

static __inline__ CGPoint CGPointFromGLKVector2(GLKVector2 v) {
	return (CGPoint){v.x, v.y};
}

static __inline__ CGPoint CGPointFromGLKVector3(GLKVector2 v) {
	return (CGPoint){v.x, v.y};
}

static __inline__ CGPoint CGPointFromGLKVector4(GLKVector2 v) {
	return (CGPoint){v.x, v.y};
}

//CGPoint to GLKVec*

static __inline__ GLKVector2 GLKVector2FromCGPoint(CGPoint v) {
	return (GLKVector2){v.x, v.y};
}

static __inline__ GLKVector3 GLKVector3FromCGPoint(CGPoint v) {
	return (GLKVector3){v.x, v.y, 0.0f};
}

static __inline__ GLKVector4 GLKVector4FromCGPoint(CGPoint v) {
	return (GLKVector4){v.x, v.y, 0.0f, 0.0f};
}

//GLKVec* to CGSize

static __inline__ CGSize CGSizeFromGLKVector2(GLKVector2 v) {
	return (CGSize){v.x, v.y};
}

static __inline__ CGSize CGSizeFromGLKVector3(GLKVector2 v) {
	return (CGSize){v.x, v.y};
}

static __inline__ CGSize CGSizeFromGLKVector4(GLKVector2 v) {
	return (CGSize){v.x, v.y};
}

//CGSize to GLKVec*

static __inline__ GLKVector2 GLKVector2FromCGSize(CGSize v) {
	return (GLKVector2){v.width, v.height};
}

static __inline__ GLKVector3 GLKVector3FromCGSize(CGSize v) {
	return (GLKVector3){v.width, v.height, 0.0f};
}

static __inline__ GLKVector4 GLKVector4FromCGSize(CGSize v) {
	return (GLKVector4){v.width, v.height, 0.0f, 0.0f};
}

//CGColor to GLKVector4

GLKVector4 CGColorGetComponentsAsGLKVector4(CGColorRef c);

#endif

