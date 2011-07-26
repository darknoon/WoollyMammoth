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

#import "WMEAGLContext.h"

extern "C" {
#import "SimplexNoise.h"
}
CTrivialRandomGenerator rng;

#define PARTICLES_ATLAS_WIDTH 4

#define PARTICLES_USE_REAL_GRAVITY 1

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
	GLKVector3 position;
	unsigned char color[4];
	unsigned char texCoord0[2];
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
	
	const float sphereRadius = 0.53f;
	
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
		GLKQuaternion rotation;
		
		float fSin = sinf(2.0f * 2.0f * 1.0f / 30.0f);
		float fCos = cosf(2.0f * 2.0f * 1.0f / 30.0f);
		
		/* Create quaternion */
		rotation.x = noiseVec.x * fSin;
		rotation.y = noiseVec.y * fSin;
		rotation.z = noiseVec.z * fSin;
		rotation.w = fCos;
		//MatrixQuaternionRotationAxis(rotation, noiseVec, 2.0 * dt);
		quaternion *= rotation;
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

- (id)initWithPlistRepresentation:(id)inPlist;
{
	[super initWithPlistRepresentation:inPlist];
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
	
	glGenBuffers(2, particleVBOs);
	glGenBuffers(1, &particleEBO);
	
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
	
	GL_CHECK_ERROR;
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, particleEBO);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, indexBufferLength * sizeof(unsigned short), indexBuffer, GL_STATIC_DRAW);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
	GL_CHECK_ERROR;
	
	delete indexBuffer;

	return YES;
}

- (void) dealloc
{
	glDeleteBuffers(2, particleVBOs);
	delete particles;
	delete particleVertices;

	[super dealloc];
}


- (WMPatchExecutionMode)executionMode;
{
	return kWMPatchExecutionModeConsumer;
}

- (void)update;
{
	GLKVector3 gravity = (GLKVector3){inputGravityX.value, inputGravityY.value, inputGravityZ.value};

	GLKVector3 rotationRate = (GLKVector3){inputRotationX.value, inputRotationY.value, inputRotationZ.value};

	//NSLog(@"g(%f, %f, %f) rot(%f, %f, %f)", gravity.x, gravity.y, gravity.z, rotationRate.x, rotationRate.y, rotationRate.z);
	
	//TODO: pass real dt
#if 0
	double t_prev = t;
	t = CFAbsoluteTimeGetCurrent();
	double dt = t - t_prev;
	dt = fmax(1.0/30.0, fmin(dt, 1.0/60.0));
#else
	double dt = 1.0/30.0;
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
	glBindBuffer(GL_ARRAY_BUFFER, particleVBOs[currentParticleVBOIndex]);
	
	GLKVector3 spherePosition = GLKVector3Make(0.0f, 0.045f, 0.0f);
	float sz = 0.010f;
	
	const GLKVector3 offsets[4] = {
		GLKVector3Make(-sz,  sz, 0),
		GLKVector3Make( sz,  sz, 0),
		GLKVector3Make(-sz, -sz, 0),
		GLKVector3Make( sz, -sz, 0),
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
			particleVertices[4 * i + v].position = particles[i].position + spherePosition + (mat * offsets[v]);
			
			//copy color as int
			*((int *)particleVertices[4 * i + v].color) = *((int *)particles[i].color);
			
			//copy tex coord as short
			particleVertices[4 * i + v].texCoord0[0] = particles[i].atlasPosition[0] + textureCoords[v][0];
			particleVertices[4 * i + v].texCoord0[1] = particles[i].atlasPosition[1] + textureCoords[v][1];
		}
	}
	glBufferData(GL_ARRAY_BUFFER, maxParticles * 4 * sizeof(WMQuadParticleVertex), particleVertices, GL_STREAM_DRAW);
	GL_CHECK_ERROR;

	glBindBuffer(GL_ARRAY_BUFFER, 0);
	particleDataAvailable++;

}

- (void)drawWithTransform:(GLKMatrix4)transform API:(EAGLRenderingAPI)API glState:(WMEAGLContext *)inGLState;
{	
	if (particleDataAvailable < 2) return;
	
	GL_CHECK_ERROR;
	int positionLocation = [shader attributeLocationForName:@"position"];
	int texCoordLocation = [shader attributeLocationForName:@"texCoord0"];
	int colorLocation = [shader attributeLocationForName:@"color"];

	ZAssert(positionLocation != -1, @"Couldn't find position in shader!");
	ZAssert(texCoordLocation != -1, @"Couldn't find texCoord0 in shader!");
	ZAssert(colorLocation != -1, @"Couldn't find color in shader!");
	
	unsigned int enableMask = 1<<positionLocation | 1 << texCoordLocation | 1 << colorLocation;
	[inGLState setVertexAttributeEnableState:enableMask];
	
	[inGLState setDepthState:0];

	[inGLState setBlendState:DNGLStateBlendEnabled];
	
	// Use shader program.
	glUseProgram(shader.program);
	
	NSUInteger stride = sizeof(WMQuadParticleVertex);
	
	glBindBuffer(GL_ARRAY_BUFFER, particleVBOs[currentParticleVBOIndex]);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, particleEBO);
	GL_CHECK_ERROR;
	
	// Update attribute values.
	glVertexAttribPointer(positionLocation, 3, GL_FLOAT, GL_FALSE, stride, (GLvoid *)offsetof(WMQuadParticleVertex, position));
	glVertexAttribPointer(colorLocation, 4, GL_UNSIGNED_BYTE, GL_TRUE, stride, (GLvoid *)offsetof(WMQuadParticleVertex, color[0]));	
	glVertexAttribPointer(texCoordLocation, 2, GL_UNSIGNED_BYTE, GL_TRUE, stride, (GLvoid *)offsetof(WMQuadParticleVertex, texCoord0[0]) );
	
	int textureUniformLocation = [shader uniformLocationForName:@"texture"];
	if (inputTexture && textureUniformLocation != -1) {
		glBindTexture(GL_TEXTURE_2D, [inputTexture name]);			
		glUniform1i(textureUniformLocation, 0); //texture = texture 0
	}
	GL_CHECK_ERROR;
		
	int matrixUniform = [shader uniformLocationForName:@"modelViewProjectionMatrix"];
	if (matrixUniform != -1) {
		glUniformMatrix4fv(matrixUniform, 1, NO, transform.m);
	}
	GL_CHECK_ERROR;
	
#if DEBUG
	if (![shader validateProgram])
	{
		NSLog(@"Failed to validate program in shader: %@", shader);
		return;
	}
	
#endif
	
	//glDrawArrays(GL_POINTS, 0, maxParticles);
	GL_CHECK_ERROR;
	glDrawElements(GL_TRIANGLES, maxParticles * 6, GL_UNSIGNED_SHORT, 0); //use element array buffer ebo
	GL_CHECK_ERROR;
	
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
}

@end