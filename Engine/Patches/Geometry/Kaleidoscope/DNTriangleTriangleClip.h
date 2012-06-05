/*
 *  DNTriangleTriangleClip.h
 *  VideoLiveEffect
 *
 *  Created by Andrew Pouliot on 11/4/10.
 *  Copyright 2010 Darknoon. All rights reserved.
 *
 */

#import "DNKaleidoscopeGeometryVariable.h"



void clipTriangleAgainstTriangle(KaleidoscopeGeometryPoint *inTri, CGPoint *againstTri, KaleidoscopeGeometryPoint *outTris, int *outTrisUsed);

void reflectVertices8(KaleidoscopeGeometryPoint *inPoints, size_t inPointsCount, float inAspectRatio, KaleidoscopeGeometryPoint *outPoints, NSUInteger *outPointsCount);

KaleidoscopeGeometryPoint pointWithBasis(int uc, int vc, CGPoint origin, CGPoint offset, CGPoint basisU, CGPoint basisV, float maxS, float maxT);

static inline CGPoint diff(CGPoint a, CGPoint b) {
	return (CGPoint) {a.x - b.x, a.y - b.y};
}

static inline CGPoint add(CGPoint a, CGPoint b) {
	return (CGPoint) {a.x + b.x, a.y + b.y};
}

static inline float distance(CGPoint a, CGPoint b) {
	const CGPoint d = {a.x - b.x, a.y - b.y};
	return sqrtf(d.x*d.x + d.y*d.y);
}
