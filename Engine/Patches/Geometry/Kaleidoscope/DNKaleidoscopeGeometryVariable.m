//
//  KaleidoscopeGeometry.m
//  CaptureTest
//
//  Created by Andrew Pouliot on 8/21/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "DNKaleidoscopeGeometryVariable.h"

#import "DNTriangleTriangleClip.h"

#import "WMRenderObject.h"

const float DNKaleidoscopeGeometryVariableMinMirrorAngle = 2.0f * M_PI / (KaleidoscopeGeometryVariableMaxN - 1);
const float DNKaleidoscopeGeometryVariableMaxMirrorAngle = 2.0f * M_PI;

@implementation DNKaleidoscopeGeometryVariable

@synthesize maxS;
@synthesize maxT;
@synthesize offset;
@synthesize triangleIndices;
@synthesize triangleIndicesCount;
@synthesize textureCoordinateAngle;
@synthesize mirrorAngle;
@synthesize aspectRatioCorrection;
@synthesize fadeConstant;
@synthesize pointsCount;
@synthesize scale;
@synthesize textureCoordinateScale;

- (id) init {
	self = [super init];
	if (self == nil) return self; 
	
	scale = 1.5f;
	fadeConstant = 0.8f;
	textureCoordinateScale = 0.2f;
	aspectRatioCorrection = 480.f / 320.f;
	
	clipTo[0] = (CGPoint) {0, 0};
	clipTo[1] = (CGPoint) {scale / 1.2, scale / 1.2};
	clipTo[2] = (CGPoint) {scale, 0};
	
	maxS = 1.0f;
	maxT = 1.0f;
		
	mirrorAngle = M_PI_4;
	
	return self;
}

- (KaleidoscopeGeometryPoint *)points;
{
	return (KaleidoscopeGeometryPoint *)points;
}


- (void)addTrianglesToClip;
{
	imageSize.width = 2.0f * textureCoordinateScale;
	imageSize.height = 6.0f / 4.0f * textureCoordinateScale;

	basisU = (CGPoint) {.x = imageSize.width * cosf(textureCoordinateAngle), .y = imageSize.width * sinf(textureCoordinateAngle)};
	basisV = (CGPoint) {.x = imageSize.height * -sinf(textureCoordinateAngle), .y = imageSize.height * cosf(textureCoordinateAngle)};
	
	trisToClipCount = 0;
		
	const CGPoint origin = {0,0};	
	
	const int umax = 6;
	const int vmax = 6;
	
	for (int uc=0; uc<umax; uc++) {
		for (int vc=0; vc<vmax && trisToClipCount < KaleidoscopeGeometryVariableMaxN; vc++) {
			
			const KaleidoscopeGeometryPoint p0 = pointWithBasis((uc - umax/2)    , (vc - vmax/2)   , origin, offset, basisU, basisV, maxS, maxT);
			const KaleidoscopeGeometryPoint p1 = pointWithBasis((uc - umax/2) + 1, (vc - vmax/2)   , origin, offset, basisU, basisV, maxS, maxT);
			const KaleidoscopeGeometryPoint p2 = pointWithBasis((uc - umax/2)   ,  (vc - vmax/2) + 1, origin, offset, basisU, basisV, maxS, maxT);
			const KaleidoscopeGeometryPoint p3 = pointWithBasis((uc - umax/2) + 1, (vc - vmax/2) + 1, origin, offset, basisU, basisV, maxS, maxT);
			
			trisToClip[trisToClipCount][0] = p0;
			trisToClip[trisToClipCount][1] = p1;
			trisToClip[trisToClipCount][2] = p2;
			trisToClipCount++;
			
			trisToClip[trisToClipCount][0] = p1;
			trisToClip[trisToClipCount][1] = p2;
			trisToClip[trisToClipCount][2] = p3;
			trisToClipCount++;
		}
	}
	
}

- (void)setOffset:(CGPoint)inOffset;
{
	offset.x = fmodf(inOffset.x + 1.0 + 2.0f, 2.0f) - 1.f;
	offset.y = fmodf(inOffset.y + 1.0 + 2.0f, 2.0f) - 1.f;
}

- (void)generateBuffers;
{
	[self addTrianglesToClip];
	
	mirrorAngle = fminf(fmaxf(DNKaleidoscopeGeometryVariableMinMirrorAngle, mirrorAngle), DNKaleidoscopeGeometryVariableMaxMirrorAngle);
	
	//size_t vertexSize = KaleidoscopeGeometryVariableMaxN + 1;
	size_t triangleIndicesSize = KaleidoscopeGeometryVariableMaxN * 8 * 8 * 3;
	
	if (!triangleIndices) {
		triangleIndices = malloc(triangleIndicesSize * sizeof(unsigned short));
	}
	
	clippedTrisCount = 0;
	for (int i=0; i<trisToClipCount; i++) {
		int trisUsed = 0;
		clipTriangleAgainstTriangle(trisToClip[i], clipTo, clippedTris[clippedTrisCount], &trisUsed);
		clippedTrisCount += trisUsed;		
	}
	
	//Reflect vertices around
	pointsCount = 0;
	reflectVertices8((KaleidoscopeGeometryPoint *)clippedTris, clippedTrisCount * 3, aspectRatioCorrection, (KaleidoscopeGeometryPoint *)points, &pointsCount);
	
	//For now, just output stupid triangle indices
	for (int i=0; i<triangleIndicesSize; i++) {
		triangleIndices[i] = i;
	}
	triangleIndicesCount = pointsCount;
	
	
}

- (void)dealloc
{
	free(triangleIndices);
}

@end
