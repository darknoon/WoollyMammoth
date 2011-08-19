//
//  WMQuadParticleSystem.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 11/27/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Random.h"
#import "WMPatch.h"

#import "WMRenderCommon.h"

#import "WMPorts.h"

struct WMQuadParticle;

struct WMQuadParticleVertex;

@class WMStructuredBuffer;
@class WMTexture2D;
@class WMShader;

@interface WMQuadParticleSystem : WMPatch {
	
	//Take data from accelerometer
	
	WMVector3Port *inputRotation;
	WMVector3Port *inputGravity;
	WMNumberPort *inputRadius;
	WMNumberPort *inputParticleSize;
	
	WMImagePort *inputTexture;
	
	WMRenderObjectPort *outputObject;
}

@end
