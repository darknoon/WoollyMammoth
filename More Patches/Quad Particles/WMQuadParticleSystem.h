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

@interface WMQuadParticleSystem : WMPatch

@property (nonatomic, readonly) WMVector3Port *inputRotation;
@property (nonatomic, readonly) WMVector3Port *inputGravity;
@property (nonatomic, readonly) WMNumberPort *inputRadius;
@property (nonatomic, readonly) WMNumberPort *inputParticleSize;
@property (nonatomic, readonly) WMImagePort *inputTexture;

@property (nonatomic, readonly) WMRenderObjectPort *outputObject;

@end
