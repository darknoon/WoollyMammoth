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

struct WMQuadParticle;

struct WMQuadParticleVertex;

@class WMTexture2D;
@class WMShader;

@interface WMQuadParticleSystem : WMPatch {
@public
	NSUInteger maxParticles;
	//Evaluates the noise function for every nth particle
	NSUInteger particleUpdateSkip;
	//The current index modulo particleUpdateSkip to start
	NSUInteger particleUpdateIndex;
	WMQuadParticle *particles;
	
	WMQuadParticleVertex *particleVertices;
	
	//0 when no data, 1 when 1st buffer, filled 2 when both
	int particleDataAvailable;
	NSUInteger currentParticleVBOIndex;
	GLuint particleVBOs[2];
	
	//Holds indices. always the same, as each particle is a quad! ie boring (0,1,2, 1,2,3 … )
	GLuint particleEBO;
	
	GLKVector4 startColor;
	float deltaAlpha;
	
	GLKVector3 particleCentroid;
	
	float turbulence;
	
	double t;
	
	//Potentially slower. Try turning off for performance
	BOOL zSortParticles;
	
	WMShader *shader;
	WMTexture2D *inputTexture;
}

@end
