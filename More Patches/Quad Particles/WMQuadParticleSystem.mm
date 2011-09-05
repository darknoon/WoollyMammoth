//
//  WMQuadParticleSystem.m
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 11/27/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "WMQuadParticleSystem.h"

#import "GLKMath_cpp.h"

#import "WMShader.h"
#import "WMEngine.h"
#import "WMTexture2D.h"
#import "WMRenderObject.h"

#import "WMEAGLContext.h"

extern "C" {
#import "SimplexNoise.h"
}
CTrivialRandomGenerator rng;

#define PARTICLES_ATLAS_WIDTH 4

#define PARTICLES_USE_REAL_GRAVITY 1

@interface WMQuadParticleSystem () {
	//Internal
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
	WMStructuredBuffer *particleVertexBuffers[2];
	
	//Holds indices. always the same, as each particle is a quad! ie boring (0,1,2, 1,2,3 … )
	WMStructuredBuffer *particleIndexBuffer;
	
	//Current values of the input ports
	float radius;
	float particleSize;
	
	GLKVector3 particleCentroid;
	
	float turbulence;
	
	double t;
	
	//Potentially slower. Try turning off for performance
	BOOL zSortParticles;
	
	WMShader *shader;
	WMTexture2D *defaultTexture;
	WMRenderObject *renderObject;
}
@end

struct WMQuadParticle {
	GLKVector3 position;
	GLKVector3 velocity;
	GLKVector3 noiseVec;
	GLKQuaternion quaternion;
	unsigned char color[4];
	char atlasPosition[2]; //texture coord at origin 0-255 range
	float opposition; //Random float, basically how much it gets pushed out from the centroid
	void update(double dt, double t, int i, GLKVector3 gravity, WMQuadParticleSystem *sys);
	void init();
	void updateNoise(double t);
};

struct WMQuadParticleVertex {
	GLKVector4 position;
	unsigned char color[4];
	unsigned char texCoord0[2];
};

WMStructureField WMQuadParticleVertex_fields[] = {
	{.name = "position",  .type = WMStructureTypeFloat,        .count = 4, .normalized = NO,  .offset = offsetof(WMQuadParticleVertex, position)},
	{.name = "color",     .type = WMStructureTypeUnsignedByte, .count = 4, .normalized = YES, .offset = offsetof(WMQuadParticleVertex, color)},
	{.name = "texCoord0", .type = WMStructureTypeUnsignedByte, .count = 2, .normalized = YES, .offset = offsetof(WMQuadParticleVertex, texCoord0)},
};

void WMQuadParticle::updateNoise(double t) {
	const float noiseScale = 5.f;
	//Disturb randomly
	GLKVector3 noisePosX = noiseScale * position + GLKVector3Make(0.000000f, 12.252f, 1230.2685f) + t * GLKVector3Make(0.2f, 0.0f, 1.2f);
	GLKVector3 noisePosY = noiseScale * position + GLKVector3Make(7833.632f, 10.002f, 1242.8365f) + t * GLKVector3Make(0.0f, 1.0f, 0.2f);
	GLKVector3 noisePosZ = noiseScale * position + GLKVector3Make(2673.262f, 12.252f, 1582.1523f) + t * GLKVector3Make(-1.f, 0.0f, 0.0f);
	
	noiseVec = GLKVector3Make(simplexNoise3(noisePosX.x, noisePosX.y, noisePosX.z),
					simplexNoise3(noisePosY.x, noisePosY.y, noisePosY.z),
					simplexNoise3(noisePosZ.x, noisePosZ.y, noisePosZ.z));
	
}

void WMQuadParticle::update(double dt, double t, int i, GLKVector3 gravity, WMQuadParticleSystem *sys) {
	position += dt * velocity;
	
	const float mass = 0.01f;
	//Elasticity of collision with sphere
	const float elasticity = 0.70f;
	const float coefficientOfDrag = 0.07f;
	
	GLKVector3 force = GLKVector3Make(0.0f, 0.0f, 0.0f);
	force += mass * 0.08 * gravity; // add gravitational force, cheat
	
	float v2 = lengthSquared(velocity);
	float vl = sqrtf(v2);
	if (v2 > 10.f) {
		v2 = 10.f;
	}
	GLKVector3 drag = -coefficientOfDrag * v2 * (1.0f/vl) * velocity;
	force += drag;
	
	// TODO: do using force for v^2 drag
	// velocity *= 0.99;
	
	float turbulenceForce = 0.1f;
	
	//	GLKVector3 randomVec = GLKVector3Make(rng.randF(-1.0f, 1.0f), rng.randF(-1.0f, 1.0f), rng.randF(-1.0f, 1.0f));
	force += turbulenceForce * sys->turbulence * noiseVec;
	
	const float particleOppositionForce = 0.0001f;
	//Push away from the centroid of other particles
	const float coff = 0.1f;
	//Force = opposition * 0.1 / (10.f * dist^2 + coff)
	GLKVector3 displacementFromFromCentroid = position - sys->particleCentroid;
	
	//TODO: can we eliminate this sqrt?
	float distanceFromFromCentroid2 = lengthSquared(displacementFromFromCentroid);
	force += opposition * (particleOppositionForce / (10.f * distanceFromFromCentroid2 + coff)) * (displacementFromFromCentroid / sqrtf(distanceFromFromCentroid2));
	
	const float sphereRadius = sys->radius;
	
	//Constrain to be inside sphere
	float distanceFromOrigin2 = lengthSquared(position);
	if (distanceFromOrigin2 > sphereRadius * sphereRadius) {
		//Normalize vector to constrain to unit sphere
		position = normalize(position);
		
		//Invert for normal
		GLKVector3 normal = -position;
		
		//If velocity is heading out of bounds (should always be true)
		if (dot(velocity, normal) < 0.0f) {
			velocity = elasticity * (velocity - 2.0f * dot(velocity, normal) * normal);
		}
		
		//Add in normal force
		if (dot(force, normal) < 0.0f) {
			force += dot(force, normal) * normal;
		}
		
		//Scale back to sphere size
		position *= sphereRadius;
	} else {
		//If we're not on the edge of the sphere
		//Have the particle kind of randomly rotate, yay

		quaternion = GLKQuaternionNormalize(quaternion * GLKQuaternionMakeWithAngleAndVector3Axis(0.2 / dt, noiseVec));
	}
	
	
	const float mass_inv = 1.0f/mass;
	velocity += force * mass_inv * dt;
	
	float bright = 0.85 + 0.1 * position.z;
	
	color[0] = 255 * bright;
	color[1] = 255 * bright;
	color[2] = 255 * bright;
	color[3] = 255;
}

void WMQuadParticle::init() {
	const float vinitial = 1.0;
	velocity = GLKVector3Make(rng.randF(-vinitial,vinitial), rng.randF(-vinitial,vinitial), rng.randF(-vinitial,vinitial));
	
	noiseVec = GLKVector3Make(0,0,0);

	//Randomize position in sphere
	const float pinitial = 0.6f;
	int misses = 0;
	position = GLKVector3Make(0,0,0);
	do {
		position = GLKVector3Make(rng.randF(-pinitial,pinitial), rng.randF(-pinitial,pinitial), rng.randF(-pinitial,pinitial));
		misses++;
	} while (lengthSquared(position) > 0.4f * 0.4f);
	
	opposition = rng.randF();
	
	//Randomize position in atlas
	atlasPosition[0] = (rng.randI() % PARTICLES_ATLAS_WIDTH) * (255 / PARTICLES_ATLAS_WIDTH);
	atlasPosition[1] = (rng.randI() % PARTICLES_ATLAS_WIDTH) * (255 / PARTICLES_ATLAS_WIDTH);
	
	quaternion = GLKQuaternionIdentity;
	
	color[0] = 255;
	color[1] = 255;
	color[2] = 255;
	color[3] = 255;
}

int particleZCompare(const void *a, const void *b) {
	return (((WMQuadParticle *)a)->position.z >  ((WMQuadParticle *)b)->position.z) ? 1 : - 1;
}



@implementation WMQuadParticleSystem 

+ (NSString *)category;
{
    return WMPatchCategoryGeometry;
}

+ (NSString *)humanReadableTitle {
    return @"Snow Globe";
}

+ (void)load;
{
	@autoreleasepool {
		[self registerPatchClass];
	}
}

+ (id)defaultValueForInputPortKey:(NSString *)inKey;
{
	if ([inKey isEqualToString:@"inputRadius"]) {
		return [NSNumber numberWithFloat:1.0f];
	}
	return nil;
	
}

- (id)initWithPlistRepresentation:(id)inPlist;
{
	self = [super initWithPlistRepresentation:inPlist];
	if (self == nil) return self; 
	
	maxParticles = 2000;
	
	particleUpdateSkip = 12;
	particleUpdateIndex = 0;
	
	zSortParticles = NO;
	
	return self;
}

- (BOOL)setup:(WMEAGLContext *)context;
{
	//TODO: error handling
	particles = new WMQuadParticle[maxParticles];
	
	particleVertices = new WMQuadParticleVertex[maxParticles * 4];
	for (int i=0; i<maxParticles; i++) {
		particles[i].init();
	}
	
	renderObject = [[WMRenderObject alloc] init];
	
	renderObject.renderBlendState = DNGLStateBlendEnabled;
	renderObject.renderDepthState = 0;
	
	NSError *defaultShaderError = nil;
	
	NSString *vsh = [[NSString alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"SnowParticle" withExtension:@"vsh"] encoding:NSASCIIStringEncoding error:NULL];
	NSString *fsh = [[NSString alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"SnowParticle" withExtension:@"fsh"] encoding:NSASCIIStringEncoding error:NULL];
	
	shader = [[WMShader alloc] initWithVertexShader:vsh
									 fragmentShader:fsh
											  error:&defaultShaderError];
	
	WMStructureDefinition *vboDef = [[WMStructureDefinition alloc] initWithFields:WMQuadParticleVertex_fields count:3 totalSize:sizeof(struct WMQuadParticleVertex)];
	vboDef.shouldAlignTo4ByteBoundary = YES;
	particleVertexBuffers[0] = [[WMStructuredBuffer alloc] initWithDefinition:vboDef];
	particleVertexBuffers[1] = [[WMStructuredBuffer alloc] initWithDefinition:vboDef];
	
	WMStructureDefinition *indexStructure = [[WMStructureDefinition alloc] initWithAnonymousFieldOfType:WMStructureTypeUnsignedShort];
	
	particleIndexBuffer = [[WMStructuredBuffer alloc] initWithDefinition:indexStructure];
	
	//Create our index buffer. 2 triangles = 6 indices per particle
	size_t indexBufferLength = maxParticles * 6;
	//TODO: maybe use map buffer here (better memory allocation?)
	unsigned short *indexBuffer = new unsigned short[indexBufferLength];
	
	//Fill up the index buffer lols no sharts only shorts here
	for (int i=0; i<maxParticles; i++) {
		//TODO: is this the correct winding???
		indexBuffer[6 * i + 0] = 4 * i + 0;
		indexBuffer[6 * i + 1] = 4 * i + 1;
		indexBuffer[6 * i + 2] = 4 * i + 2;
		indexBuffer[6 * i + 3] = 4 * i + 1;
		indexBuffer[6 * i + 4] = 4 * i + 2;
		indexBuffer[6 * i + 5] = 4 * i + 3;
	}
	
	[particleIndexBuffer appendData:indexBuffer withStructure:indexStructure count:indexBufferLength];
		
	delete indexBuffer;
	
	
	return YES;
}

- (void)cleanup:(WMEAGLContext *)context;
{
	renderObject = nil;
	
	particleVertexBuffers[0] = nil;
	particleVertexBuffers[1] = nil;
	delete particles;
	delete particleVertices;
}


- (void)update;
{
	GLKVector3 gravity = inputGravity.v;
	GLKVector3 rotationRate = inputRotation.v;

	//NSLog(@"g(%f, %f, %f) rot(%f, %f, %f)", gravity.x, gravity.y, gravity.z, rotationRate.x, rotationRate.y, rotationRate.z);
	
	//TODO: pass real dt
#if 0
	double t_prev = t;
	t = CFAbsoluteTimeGetCurrent();
	double dt = t - t_prev;
	dt = fmax(1.0/30.0, fmin(dt, 1.0/60.0));
#else
	double dt = 1.0/60.0;
	t += dt;
#endif

	const float turbulenceDecay = 0.99f;
	const float turbulenceStrength = 0.1f;
	GLKMatrix4 rotation;
	if (t > 0.5) {
		turbulence = turbulence * turbulenceDecay + (1.0 - turbulenceDecay) * turbulenceStrength * (fabsf(rotationRate.x) + fabsf(rotationRate.y) + fabsf(rotationRate.z));
		turbulence = fmaxf(0.0, fminf(turbulence, 1.0));
		
#if TARGET_IPHONE_SIMULATOR
		turbulence = 0.5;
#endif
		//TODO: this is probably not the best way to create a matrix based on rotation by euler angles. Quaternions ftw?

		GLKMatrix4 rotX = GLKMatrix4MakeXRotation(dt * rotationRate.x);
		GLKMatrix4 rotY = GLKMatrix4MakeYRotation(dt * rotationRate.y);
		GLKMatrix4 rotZ = GLKMatrix4MakeYRotation(dt * rotationRate.z);
		
		rotation = rotZ * rotY * rotX;		
	} else {
		rotation = GLKMatrix4Identity;
	}

	for (int i=particleUpdateIndex; i<maxParticles; i+=particleUpdateSkip) {
		particles[i].updateNoise(t);
	}
	particleUpdateIndex = (particleUpdateIndex + 1) % particleUpdateSkip;
	
	
	//Update particles
	for (int i=0; i<maxParticles; i++) {
		particles[i].update(dt, t, i, gravity, self);

		
		//Rotate with torque! (try to anyway!)
		particles[i].position = rotation * particles[i].position;
	}
	//Update centroid
	particleCentroid = GLKVector3Make(0,0,0);
	for (int i=0; i<maxParticles; i++) {
		particleCentroid += particles[i].position;
	}
	particleCentroid *= 1.0f / maxParticles;
	
	//Sort particles (if necessary)
	if (zSortParticles)
		qsort(particles, maxParticles, sizeof(WMQuadParticle), particleZCompare);
	
	//Swap buffers and write particles to VBO
	currentParticleVBOIndex = !currentParticleVBOIndex;
	WMStructuredBuffer *currentBuffer = particleVertexBuffers[currentParticleVBOIndex];
	
	GLKVector3 spherePosition = GLKVector3Make(0.0f, 0.045f, 0.0f);
	float sz = particleSize;
	
	const GLKVector3 offsets[4] = {
		{-sz,  sz, 0},
		{ sz,  sz, 0},
		{-sz, -sz, 0},
		{ sz, -sz, 0},
	};
	
	const unsigned char an = (255 / PARTICLES_ATLAS_WIDTH);
	const unsigned char textureCoords[4][2] = {
		{0,0},
		{an,0},
		{0,an},
		{an,an},
	};
	
	for (int i=0; i<maxParticles; i++) {
		//TODO: just rotate the basis vectors instead of incurring an expensive matrix multiplication here!		
		GLKMatrix4 mat = GLKMatrix4MakeWithQuaternion(particles[i].quaternion);
		for (int v=0; v<4; v++) {
			//Calculate the particle position
			particleVertices[4 * i + v].position = GLKVector4MakeWithVector3(particles[i].position + spherePosition + (mat * offsets[v]), 1.0f);
			
			//copy color as int
			*((int *)particleVertices[4 * i + v].color) = *((int *)particles[i].color);
			
			//copy tex coord as short
			particleVertices[4 * i + v].texCoord0[0] = particles[i].atlasPosition[0] + textureCoords[v][0];
			particleVertices[4 * i + v].texCoord0[1] = particles[i].atlasPosition[1] + textureCoords[v][1];
		}
	}
	
	//Replace all data with new data
	//TODO: what about a wrapper around glBindBuffer() here?
	[currentBuffer replaceData:particleVertices withStructure:currentBuffer.definition inRange:(NSRange){0, maxParticles * 4}];
	
	//NSLog(@"particle vertex size: %ld position @ %ld, color @ %ld, texCoord0 @ %ld", sizeof(WMQuadParticleVertex), offsetof(WMQuadParticleVertex, position), offsetof(WMQuadParticleVertex, color), offsetof(WMQuadParticleVertex, texCoord0));
		
	//NSLog(@"curb; %@", [currentBuffer debugDescription]);
	
	particleDataAvailable++;
}

- (BOOL)execute:(WMEAGLContext *)context time:(double)time arguments:(NSDictionary *)args;
{	
	radius = MAX(0.1f, MIN(inputRadius.value, 2.0f));
	particleSize = MAX(0.001f, MIN(inputParticleSize.value * 0.05f, 0.05f));

	[self update];
	
	if (particleDataAvailable < 2) {
		//Still warming data cache
		return YES;
	}
	
	if (inputTexture.image) {
		[renderObject setValue:inputTexture.image forUniformWithName:@"texture"];
		if (defaultTexture) {
			defaultTexture = nil;
		}
	} else {
		if (!defaultTexture) {
			defaultTexture = [[WMTexture2D alloc] initWithImage:[UIImage imageNamed:@"SnowChunk.png"]];
		}
		[renderObject setValue:defaultTexture forUniformWithName:@"texture"];
	}
	GL_CHECK_ERROR;

	GLKMatrix4 m = context.modelViewMatrix;
	[renderObject setValue:[NSValue valueWithBytes:&m objCType:@encode(GLKMatrix4)] forUniformWithName:@"modelViewProjectionMatrix"];
	
	renderObject.shader = shader;
	
	renderObject.vertexBuffer = particleVertexBuffers[currentParticleVBOIndex];
	renderObject.indexBuffer = particleIndexBuffer;
	
	outputObject.object = renderObject;
	
	return YES;
}

@end