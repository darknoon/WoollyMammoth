//
//  WMParticleSystem.h
//  WMViewer
//
//  Created by Andrew Pouliot on 4/26/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMPatch.h"
#import "WMRenderCommon.h"

//TODO: support "interpolate size and color"
//TODO: figure out how attraction algorithm works, implement
//TODO: add a method to convert between FBO and GL coords so the points will be scaled correctly
@class WMShader;
@interface WMParticleSystem : WMPatch {
	WMIndexPort *inputCount;
	WMNumberPort *inputPositionX;
	WMNumberPort *inputPositionY;
	WMNumberPort *inputPositionZ;
	WMColorPort *inputColor;
	WMNumberPort *inputVelocityMinX;
	WMNumberPort *inputVelocityMaxX;
	WMNumberPort *inputVelocityMinY;
	WMNumberPort *inputVelocityMaxY;
	WMNumberPort *inputVelocityMinZ;
	WMNumberPort *inputVelocityMaxZ;
	WMNumberPort *inputMinSize;
	WMNumberPort *inputMaxSize;
	WMNumberPort *inputLifeTime;
	WMNumberPort *inputAttraction;
	WMNumberPort *inputGravity;
	WMImagePort *inputImage;
	WMIndexPort *inputBlending;
	WMNumberPort *inputSizeDelta;
	WMNumberPort *inputRedDelta;
	WMNumberPort *inputGreenDelta;
	WMNumberPort *inputBlueDelta;
	WMNumberPort *inputOpacityDelta;

	float startUpDelay;
	NSUInteger particleCount;
	NSUInteger maxParticleCount;
	NSUInteger activeParticleCount;
	
	void *particleData;
	
	int rndSeed;
	
	int particleDataAvailable;
	NSUInteger currentParticleVBOIndex;
	GLuint particleVBOs[2];
	
	WMShader *shader;

}

@end
