//
//  KaleidoscopeGeometry.h
//  CaptureTest
//
//  Created by Andrew Pouliot on 8/21/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WMStructuredBuffer;

#define KaleidoscopeGeometryVariableMaxN (6 * 6 * 2)

typedef struct {
	float v[2];
	float tc[2];
} KaleidoscopeGeometryPoint;

@interface DNKaleidoscopeGeometryVariable : NSObject {
	float scale;
	float textureCoordinateScale;
	float textureCoordinateAngle;
	float fadeConstant;
	
	float mirrorAngle;
	
	float aspectRatioCorrection;

	float maxS;
	float maxT;
	
	CGPoint clipTo[3];
	
	KaleidoscopeGeometryPoint trisToClip[KaleidoscopeGeometryVariableMaxN][3];
	size_t trisToClipCount;
	
	//At most 4 output triangles per input triangle
	KaleidoscopeGeometryPoint clippedTris[KaleidoscopeGeometryVariableMaxN * 8][3];
	size_t clippedTrisCount;
	
	KaleidoscopeGeometryPoint points[KaleidoscopeGeometryVariableMaxN * 8 * 8][3];
	NSUInteger pointsCount;
	
	CGPoint basisU;
	CGPoint basisV;
	
	CGSize imageSize;
	
	CGPoint offset;
		
	unsigned short *triangleIndices;
	NSUInteger triangleIndicesCount;
}

@property (nonatomic, assign) float maxS;
@property (nonatomic, assign) float maxT;
@property (nonatomic, assign) CGPoint offset;
@property (nonatomic, assign) float textureCoordinateAngle;

//In radians
@property (nonatomic, assign) float mirrorAngle;

@property (nonatomic, assign) float aspectRatioCorrection;
@property (nonatomic, assign) float fadeConstant;
@property (nonatomic, assign) float scale;
@property (nonatomic, assign) float textureCoordinateScale;

//Output
@property (nonatomic, readonly) NSUInteger pointsCount;
- (KaleidoscopeGeometryPoint *)points;

@property (nonatomic, assign) NSUInteger triangleIndicesCount;
@property (nonatomic, readonly) unsigned short *triangleIndices;


- (void)generateBuffers;

@end
