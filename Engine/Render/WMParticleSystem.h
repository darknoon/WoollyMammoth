//
//  WMParticleSystem.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 11/27/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMRenderable.h"
#import "Random.h"

struct WMParticle;

struct WMParticleVertex;
@class Texture2D;

@interface WMParticleSystem : WMPatch {
@public
	NSUInteger maxParticles;
	//Evaluates the noise function for every nth particle
	NSUInteger particleUpdateSkip;
	//The current index modulo particleUpdateSkip to start
	NSUInteger particleUpdateIndex;
	WMParticle *particles;
	
	WMParticleVertex *particleVertices;
	
	//0 when no data, 1 when 1st buffer, filled 2 when both
	int particleDataAvailable;
	NSUInteger currentParticleVBOIndex;
	GLuint particleVBOs[2];
	
	//Holds indices. always the same, as each particle is a quad! ie boring (0,1,2, 1,2,3 … )
	GLuint particleEBO;
	
	VECTOR4 startColor;
	float deltaAlpha;
	
	Vec3 particleCentroid;
	
	float turbulence;
	
	double t;
	
	//Potentially slower. Try turning off for performance
	BOOL zSortParticles;
	
	WMShader *shader;
	Texture2D *inputTexture;
}

@end
