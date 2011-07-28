//
//  WMParticleSystem.m
//  WMViewer
//
//  Created by Andrew Pouliot on 4/26/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMParticleSystem.h"

#import "WMEAGLContext.h"
#import "WMShader.h"

#import "WMMathUtil.h"
#import "WMTexture2D.h"

const unsigned int WMParticleSystemMaxParticles = 4096;

//TODO: pad?
typedef struct {
	GLKVector3 p;
	float size;
	float c[4];
	//Used only in update
	GLKVector3 v;
	float life;
} WMParticle;

@implementation WMParticleSystem

+ (NSString *)category;
{
    return WMPatchCategoryGeometry;
}

+ (void)load;
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self registerToRepresentClassNames:[NSSet setWithObject:@"QCParticleSystem"]];
	[pool drain];
}
- (id)initWithPlistRepresentation:(id)inPlist;
{
	self = [super initWithPlistRepresentation:inPlist];
	if (!self) return nil;
	
	rndSeed = 1251213;
	
	return self;
}

- (BOOL)setPlistState:(id)inPlist;
{
	BOOL ok = [super setPlistState:inPlist];
	if (ok) {
		startUpDelay = [[inPlist objectForKey:@"startUpDelay"] floatValue];
		rndSeed = [[inPlist objectForKey:@"randomSeed"] intValue];
	}
	return ok;
}

- (BOOL)setup:(WMEAGLContext *)context;
{
	//Check ours valuzz
	
	//Create buffers we'll need
	glGenBuffers(2, particleVBOs);
	
	ZAssert(!particleData, @"Shouldn't be doing setup again!");
	
	maxParticleCount = [inputCount index];
	maxParticleCount = MIN(maxParticleCount, WMParticleSystemMaxParticles);
	particleData = malloc(maxParticleCount * sizeof(WMParticle));
	if (!particleData) {
		NSLog(@"malloc particles out of memory");
		return NO;
	}
	
	//Initialize particle array
	WMParticle *pbuf = (WMParticle *)particleData;
	for (int i=0; i<maxParticleCount; i++) {
		//Give each a positive life so they don't respawn right away
		pbuf[i].life = startUpDelay * randF(&rndSeed);
	}
	
	NSString *vertexShader = @"\
	attribute vec4 position;\
	attribute vec4 color;\
	uniform mat4 modelViewProjectionMatrix;\
	varying lowp vec4 v_color;\
	void main() {\
    	gl_Position = modelViewProjectionMatrix * vec4(position.x, position.y, position.z, 1.0);\
		gl_PointSize = 480.0 * position.w;\
		v_color = color;\
	}";
	
	NSString *fragmentShader = @"\
	uniform sampler2D texture;\
	varying lowp vec4 v_color;\
	void main() {\
		gl_FragColor = texture2D(texture, gl_PointCoord) * v_color * v_color.a;\
	}";
	
	shader = [[WMShader alloc] initWithVertexShader:vertexShader fragmentShader:fragmentShader error:NULL];
	GL_CHECK_ERROR;

	return YES;
}


- (void)cleanup:(WMEAGLContext *)context;
{
	glDeleteBuffers(2, particleVBOs);
	
	free(particleData);
	particleData = NULL;
}

- (void)update:(float)dt;
{	
	
	const float spawnColor[4] = {inputColor.v.r};
	const float spawnSizeRange[2] = {inputMinSize.value, inputMaxSize.value};
	const float spawnVelocityRangeX[2] = {inputVelocityMinX.value, inputVelocityMaxX.value};
	const float spawnVelocityRangeY[2] = {inputVelocityMinY.value, inputVelocityMaxY.value};
	const float spawnVelocityRangeZ[2] = {inputVelocityMinZ.value, inputVelocityMaxZ.value};
	const float spawnLife = inputLifeTime.value;
	const GLKVector3 spawnPosition = inputPosition.v;
	
	const float colorDelta[4] = {inputRedDelta.value, inputGreenDelta.value, inputBlueDelta.value, inputOpacityDelta.value};
	const float sizeDelta = inputSizeDelta.value;

	const float gravity = inputGravity.value;
	
	WMParticle *pbuf = (WMParticle *)particleData;
	for (int i=0; i<particleCount; i++) {
		WMParticle *p = &pbuf[i];
		if (p->life > 0) {
			//TODO: use better vector ops here
			p->v.y += gravity * dt;
			
			p->p.x += 0.1 * p->v.x * dt;
			p->p.y += 0.1 * p->v.y * dt;
			p->p.z += 0.1 * p->v.z * dt;
			p->size += sizeDelta * dt;
			
			p->c[0] += colorDelta[0] * dt;
			p->c[1] += colorDelta[1] * dt;
			p->c[2] += colorDelta[2] * dt;
			p->c[3] += colorDelta[3] * dt;
			
			p->life -= dt;
		} else {
			//Spawn particle
			//Random position in cube
			p->v.x = randFR(&rndSeed, spawnVelocityRangeX[0], spawnVelocityRangeX[1]);
			p->v.y = randFR(&rndSeed, spawnVelocityRangeY[0], spawnVelocityRangeY[1]);
			p->v.z = randFR(&rndSeed, spawnVelocityRangeZ[0], spawnVelocityRangeZ[1]);

			p->p.x = spawnPosition.x;
			p->p.y = spawnPosition.y;
			p->p.z = spawnPosition.z;
			p->size = randFR(&rndSeed, spawnSizeRange[0], spawnSizeRange[1]);
			
			p->c[0] = spawnColor[0];
			p->c[1] = spawnColor[1];
			p->c[2] = spawnColor[2];
			p->c[3] = spawnColor[3];
			
			p->life = spawnLife;
		}
	}
}

- (BOOL)execute:(WMEAGLContext *)context time:(double)time arguments:(NSDictionary *)args;
{	
	GL_CHECK_ERROR;
	int positionLocation = [shader attributeLocationForName:@"position"];
	int colorLocation = [shader attributeLocationForName:@"color"];
	
	ZAssert(positionLocation != -1, @"Couldn't find position in shader!");
	ZAssert(colorLocation != -1, @"Couldn't find color in shader!");
	
	unsigned int enableMask = 1<<positionLocation | 1 << colorLocation;
	[context setVertexAttributeEnableState:enableMask];
	
	[context setDepthState:0];
	switch (inputBlending.index) {
		default:
		case QCBlendModeReplace:
			[context setBlendState:0];
			break;
		case QCBlendModeOver:
			[context setBlendState:DNGLStateBlendEnabled];
			break;
		case QCBlendModeAdd:
			[context setBlendState:DNGLStateBlendEnabled | DNGLStateBlendModeAdd];
			break;
	}

	
	glUseProgram(shader.program);
	GL_CHECK_ERROR;
	
	glBindBuffer(GL_ARRAY_BUFFER, particleVBOs[currentParticleVBOIndex]);
	GL_CHECK_ERROR;

	if (inputImage.image) {
		glBindTexture(GL_TEXTURE_2D, [inputImage.image name]);
		glUniform1i([shader uniformLocationForName:@"texture"], 0);
	}
	GL_CHECK_ERROR;

	//TODO: allow # max particles to change over time
	particleCount = maxParticleCount;
	
	//Update all particle positions
	[self update:1.0f/60.0f];
	
	//Write to gpu
	glBufferData(GL_ARRAY_BUFFER, maxParticleCount * sizeof(WMParticle), particleData, GL_STATIC_DRAW);
	GL_CHECK_ERROR;
	
	//Draw with gpu
	size_t stride = sizeof(WMParticle);
	//4 = grab position and size
	glVertexAttribPointer(positionLocation, 4, GL_FLOAT, GL_FALSE, stride, (GLvoid *)offsetof(WMParticle, p));
	GL_CHECK_ERROR;
	glVertexAttribPointer(colorLocation, 4, GL_FLOAT, GL_FALSE, stride, (GLvoid *)offsetof(WMParticle, c));
	GL_CHECK_ERROR;

	int matrixUniform = [shader uniformLocationForName:@"modelViewProjectionMatrix"];
	if (matrixUniform != -1) {
		glUniformMatrix4fv(matrixUniform, 1, NO, context.modelViewMatrix.m);
	}
	GL_CHECK_ERROR;

	glDrawArrays(GL_POINTS, 0, maxParticleCount);
	GL_CHECK_ERROR;
	
	glBindBuffer(GL_ARRAY_BUFFER, 0);

	
	return YES;
}

@end
