//
//  DNPCParticleCascader.m
//  ParticleCascade
//
//  Created by Andrew Pouliot on 9/19/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import "DNPCParticleCascader.h"

#define USE_MAPBUFFER 1
#define USE_DISPATCH 1

#define countof(t) (sizeof(t) / sizeof(typeof(t[0])))

#import "Random.h"
extern "C" {
#import "SimplexNoise.h"
}

static CTrivialRandomGenerator rng;

struct DNPCParticleRenderRep {
	GLKVector4 position;
	unsigned char color[4];
};

static float maxLife = 8.0;

static WMStructureField DNPCParticleRenderRep_fields[] = {
	{.name = "position",  .type = WMStructureTypeFloat,        .count = 4, .normalized = NO,  .offset = offsetof(DNPCParticleRenderRep, position)},
	{.name = "color",     .type = WMStructureTypeUnsignedByte, .count = 4, .normalized = YES, .offset = offsetof(DNPCParticleRenderRep, color)},
};


struct DNPCParticle {
	GLKVector4 noiseVec;
	GLKVector4 position;
	GLKVector4 velocity;

	float life;

	bool hidden;

	void init(DNPCParticleRenderRep *updateRep);
	void update(double dt, double t, int i, GLKVector2 p, bool touchIsDown, DNPCParticleRenderRep *updateRep);
	void updateNoise(double t);
};


@implementation DNPCParticleCascader {
	WMRenderObject *_ro;
	
	WMStructuredBuffer *_vbuf;

	int _particleUpdateSkip;
	int _particleUpdateIndex;

	int _n_particles;
	DNPCParticle *_particles;
	DNPCParticleRenderRep *_particleRenderReps;
	
	WMTexture2D *_particleImage;
	
}

- (id)initWithParticleCount:(int)count;
{
    self = [super init];
    if (!self) return nil;
	
	_ro = [[WMRenderObject alloc] init];
	_ro.renderType = GL_POINTS;
	_ro.renderBlendState = DNGLStateBlendEnabled | DNGLStateBlendModeAdd;
	
	NSError *error = nil;
	NSString *shaderName = @"Particle";
	NSString *path = [[NSBundle mainBundle] pathForResource:shaderName ofType:@"glsl"];
	NSString *shaderText = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
	
	WMShader *shader = [[WMShader alloc] initWithVertexShader:shaderText fragmentShader:shaderText error:&error];
	
	if (!shader) {
		NSLog(@"Couldn't load shader \"%@\"", shaderName);
		return nil;
	}
	
	CGFloat scale = [UIScreen mainScreen].scale;
	const CGFloat particleSize = 4;
	_particleImage = [[WMTexture2D alloc] initWithBitmapSize:(CGSize){particleSize * scale, particleSize * scale} format:kWMTexture2DPixelFormat_R8 block:^(CGContextRef ctx) {
		CGContextScaleCTM(ctx, scale, scale);
		CGContextSetFillColor(ctx, (const CGFloat[]){1, 1});
		CGContextFillEllipseInRect(ctx, CGRectInset((CGRect){0,0, particleSize, particleSize}, 0.24, 0.24));
	}];
	
	_particleUpdateSkip = 12;
	_particleUpdateIndex = 0;
	
    _ro.shader = shader;
	[_ro setValue:_particleImage forUniformWithName:@"sTexture"];
	[_ro setValue:@(particleSize * scale) forUniformWithName:@"size"];
	
	_n_particles = count;
	_particles = new DNPCParticle[_n_particles]();
	_particleRenderReps = new DNPCParticleRenderRep[_n_particles]();
	
	
	for (int i=0; i<_n_particles; i++) {
		_particles[i].init(&_particleRenderReps[i]);
	}
	
    return self;
}

- (void)dealloc
{
	delete _particles;
	delete _particleRenderReps;
}

#if USE_MAPBUFFER
- (void)updateWithTime:(double)t dt:(double)dt;
{
	//Update the slow bits
	for (int i=_particleUpdateIndex; i<_n_particles; i+=_particleUpdateSkip) {
		_particles[i].updateNoise(t);
	}
	_particleUpdateIndex = (_particleUpdateIndex + 1) % _particleUpdateSkip;
	
	if (!_vbuf) {
		WMStructureDefinition *def = [[WMStructureDefinition alloc] initWithFields:DNPCParticleRenderRep_fields count:countof(DNPCParticleRenderRep_fields)totalSize:sizeof(DNPCParticleRenderRep)];
		
		_vbuf = [[WMStructuredBuffer alloc] initWithDefinition:def];
		_vbuf.count = _n_particles;
		_ro.vertexBuffer = _vbuf;
	}
	
	[_vbuf mapForWritingWithBlock:^(void *ptr){
		DNPCParticleRenderRep *repsBuffer = (DNPCParticleRenderRep *)ptr;
		if (!repsBuffer) return;
		
#if USE_DISPATCH
		int blockSize = 16;
		int total = _n_particles; //capture int instead of ptr to self
		
		dispatch_apply(_n_particles / blockSize, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t idx) {
			
			int min = idx * blockSize;
			int max = MIN( (idx+1) * blockSize, total);
			
			for (int i=min; i<max; i++) {
				_particles[i].update(dt, t, i, _inputPoint, _touchIsDown, &repsBuffer[i]);
			}
			
		});
		
#else
		//Update particles in the shared memory area
		for (int i=0; i<_n_particles; i++) {
			_particles[i].update(dt, t, i, _inputPoint, _touchIsDown, &repsBuffer[i]);
		}
#endif
	}];
}
#else
- (void)updateWithTime:(double)t dt:(double)dt;
{
	//Update the slow bits
	for (int i=_particleUpdateIndex; i<_n_particles; i+=_particleUpdateSkip) {
		_particles[i].updateNoise(t);
	}
	_particleUpdateIndex = (_particleUpdateIndex + 1) % _particleUpdateSkip;

	for (int i=0; i<_n_particles; i++) {
		_particles[i].update(dt, t, i, _inputPoint, _touchIsDown, &_particleRenderReps[i]);
	}
}

#endif


- (void)render;
{
	if (_ro.vertexBuffer) {
		[_ro.context renderObject:_ro];
	}
}

@end


void DNPCParticle::init(DNPCParticleRenderRep *updateRep) {
	const float vinitial = 1.0;
	velocity = GLKVector4Make(rng.randF(-vinitial,vinitial), rng.randF(-vinitial,vinitial), 0.0, 0.0);
	
	life = rng.randF(0.0, maxLife);
	
	hidden = true;
	
	noiseVec = GLKVector4Make(0,0,0,0);
	
	updateRep->color[0] = 0;
	updateRep->color[1] = 0;
	updateRep->color[2] = 0;
	updateRep->color[3] = 0;
}

void DNPCParticle::updateNoise(double t) {
	//TODO: pick better / faster constants
	
	const float noiseScale = 1.f;
	//Disturb randomly
	GLKVector4 noisePosX = noiseScale * position + GLKVector4Make(0.000000f, 12.252f, 1230.2685f, 0.0f) + t * GLKVector4Make(0.2f, 0.0f, 1.2f, 0.0f);
	GLKVector4 noisePosY = noiseScale * position + GLKVector4Make(7833.632f, 10.002f, 1242.8365f, 0.0f) + t * GLKVector4Make(0.0f, 1.0f, 0.2f, 0.0f);
	GLKVector4 noisePosZ = noiseScale * position + GLKVector4Make(2673.262f, 12.252f, 1582.1523f, 0.0f) + t * GLKVector4Make(-1.f, 0.0f, 0.0f, 0.0f);
	
	noiseVec = GLKVector4Make(simplexNoise3(noisePosX.x, noisePosX.y, noisePosX.z),
							  simplexNoise3(noisePosY.x, noisePosY.y, noisePosY.z),
							  simplexNoise3(noisePosZ.x, noisePosZ.y, noisePosZ.z), 0.0);
}

void DNPCParticle::update(double dt, double t, int i, GLKVector2 p, bool touchIsDown, DNPCParticleRenderRep *updateRep) {
	
	if (life > 0.0) {
		position += dt * velocity;
		velocity *= 0.99;
		velocity += 0.01 * noiseVec;
		life -= dt;
	} else {
		hidden = !touchIsDown;
		life = rng.randF(0.0, maxLife);
		
		position = (GLKVector4){p.x, p.y, 0.0, 0.0};
		
		float theta = rng.randF(0.0, 2.0 * M_PI);
		float mag = rng.randF(0.2, 1.0);
		velocity = (GLKVector4){mag * cosf(theta), mag * sinf(theta), 0.0, 0.0};
	}
	
	updateRep->position = (GLKVector4){position.x, position.y, position.z, 1.0};
	
	
	
	if (!hidden) {
		float a = (life / maxLife) * (1.0 + 2.0 * sinf(life));
		
		const GLKVector4 baseColor = {0.6, 0.8, 1.0, 1.0};
		
		updateRep->color[0] = 255.f * MAX(0.0f, MIN(baseColor.r * a, 1.0f));
		updateRep->color[1] = 255.f * MAX(0.0f, MIN(baseColor.g * a, 1.0f));
		updateRep->color[2] = 255.f * MAX(0.0f, MIN(baseColor.b * a, 1.0f));
		updateRep->color[3] = 255.f * MAX(0.0f, MIN(baseColor.a * a, 1.0f));
	} else {
		updateRep->color[0] = 0;
		updateRep->color[1] = 0;
		updateRep->color[2] = 0;
		updateRep->color[3] = 0;
	}
}

