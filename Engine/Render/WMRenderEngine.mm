//
//  WMRenderEngine.m
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/12/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "WMRenderEngine.h"

#import "WMShader.h"
#import "WMRenderEngine.h"
#import "WMEngine.h"
#import "WMRenderable.h"
#import "WMGameObject.h"

#import "DNFramebuffer.h"
#import "Texture2D.h"
#import "WMAssetManager.h"
#import "WMTextureAsset.h"

#import "WMMathUtil.h"

#import "DNEAGLContext.h"

#define DEBUG_LOG_RENDER_MATRICES 0

@interface WMRenderEngine ()
- (void)setCameraMatrixWithRect:(CGRect)inBounds;
@end


@implementation WMRenderEngine

@synthesize context;


- (id)initWithEngine:(WMEngine *)inEngine;
{
	self = [super init];
	if (!self) return nil;
	
	engine = inEngine;
		
	context = [[DNEAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!context) {
        context = [[DNEAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
		NSLog(@"Falling back to ES 1 context because we could not create ES 2 context.");
    }
    if (!context) {
        NSLog(@"Failed to create ES context");
	}	else if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"Failed to set ES context current");
	}
	[EAGLContext setCurrentContext:context];
			
	return self;
}

- (void) dealloc
{
	// Tear down context.
    if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];
		
	[context release];
	
	[super dealloc];
}


- (void)setCameraMatrixWithRect:(CGRect)inBounds;
{
	//TODO: move this state setting to DNEAGLContext
	//glCullFace(GL_BACK);
	
	MATRIX projectionMatrix;
	GLfloat viewAngle = 35.f * M_PI / 180.0f;
	
	const float near = 0.1;
	const float far = 1000.0;
	
	const float aspectRatio = inBounds.size.width / inBounds.size.height;
	
	MatrixPerspectiveFovRH(projectionMatrix, viewAngle, aspectRatio, near, far, NO);
	
	//glDepthRangef(near, far);
	
	MATRIX viewMatrix;
	Vec3 cameraPosition(0, 0, 3.0f);
	Vec3 cameraTarget(0, 0, 0);
	Vec3 upVec(0, 1, 0);
	MatrixLookAtRH(viewMatrix, cameraPosition, cameraTarget, upVec);
	
	MatrixMultiply(cameraMatrix, viewMatrix, projectionMatrix);

#if DEBUG_LOG_RENDER_MATRICES
	
	NSLog(@"Perspective: ");
	MatrixPrint(projectionMatrix);
	
	NSLog(@"Look At: ");
	MatrixPrint(viewMatrix);

	NSLog(@"Final: ");
	MatrixPrint(cameraMatrix);
	
	Vec3 position(0,0,0);
	MatrixVec3Multiply(position, position, cameraMatrix);
	NSLog(@"Position of 0,0,0 in screen space: %f %f %f", position.x, position.y, position.z);
	
	position = Vec3(1,1,0);
	MatrixVec3Multiply(position, position, cameraMatrix);
	NSLog(@"Position of 1,1,0 in screen space: %f %f %f", position.x, position.y, position.z);
#endif
}


- (void)drawFrameRecursive:(WMGameObject *)inObject transform:(MATRIX)parentTransform;
{
	MATRIX transform;
	MatrixMultiply(transform, inObject.transform, parentTransform);
	
	WMRenderable *renderable = inObject.renderable;
	if (!renderable.hidden) {
		// NSLog(@"before %@:  %@", inObject.notes, glState);
		[renderable drawWithTransform:transform API:context.API glState:context];
		// NSLog(@"after %@: %@", inObject.notes, glState);
	}
	
	for (WMGameObject *object in inObject.children) {
		[self drawFrameRecursive:object transform:transform];
	}
}

- (void)drawFrameInRect:(CGRect)inBounds;
{
	
	BOOL doRTT = YES;
	
	[EAGLContext setCurrentContext:context];

	DNFramebuffer *outputFramebuffer = context.boundFramebuffer;
	
	CGSize contentSize = {outputFramebuffer.framebufferWidth, outputFramebuffer.framebufferHeight};
	CGSize rttSize = {contentSize.width / 2, contentSize.height / 2};
	
	if (doRTT) {
		
		if (!rttFramebuffer) {
			ZAssert(!rttTexture, @"Invalid RTT state");
			
			unsigned int rttTextureWidth = nextPowerOf2(rttSize.width);
			unsigned int rttTextureHeight = nextPowerOf2(rttSize.height);
			
			rttTexture = [[Texture2D alloc] initWithData:NULL pixelFormat:kTexture2DPixelFormat_RGBA8888 pixelsWide:rttTextureWidth pixelsHigh:rttTextureHeight contentSize:rttSize];
			rttFramebuffer = [[DNFramebuffer alloc] initWithTexture:rttTexture depthBufferDepth:0];

		}
		
		context.boundFramebuffer = rttFramebuffer;
		const CGRect renderRect = {CGPointZero, rttTexture.contentSize};
		
		CGRect rttBounds = {CGPointZero, rttSize};
		[self setCameraMatrixWithRect:rttBounds];
		glViewport(0, 0, rttSize.width, rttSize.height);
		
		
	} else {
		[self setCameraMatrixWithRect:inBounds];
		
		glViewport(0, 0, outputFramebuffer.framebufferWidth, outputFramebuffer.framebufferHeight);
	}
	
	//Draw scene
    glClearColor(0.0f, 0.0f, 0.1f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
	
	[self drawFrameRecursive:engine.rootObject transform:cameraMatrix];

	if (doRTT) {
		
		context.boundFramebuffer = outputFramebuffer;
		
		glViewport(0, 0, outputFramebuffer.framebufferWidth, outputFramebuffer.framebufferHeight);
		[self setCameraMatrixWithRect:inBounds];
		
		glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		
		context.blendState = DNGLStateBlendEnabled;
		context.depthState = 0;
		
		//Draw a screen quad
		
		//TODO: create a class that lets you define geometry programatically...
		//ie. add vertex A, B, C, D
		//    add triangles ABC BCD
		
		WMShader *shader = [engine.assetManager shaderWithName:@"DebugPositionTexture"];
		
		glUseProgram(shader.program);
		
		float scale = 1.0f;
		
		float quad[4][3] = {
			{-scale, -scale, 0},
			{-scale, scale, 0},
			{scale, -scale, 0},
			{scale, scale, 0},
		};
		float quadTCs[4][2] = {
			{1, 1},
			{1.0 - rttTexture.maxT, 1},
			{1, 1.0 - rttTexture.maxS},
			{1.0 - rttTexture.maxT, 1.0 - rttTexture.maxS},
		};
		
		[context setVertexAttributeEnableState:WMRenderableDataAvailablePosition | WMRenderableDataAvailableTexCoord0];
		
		glVertexAttribPointer(WMShaderAttributePosition, 3, GL_FLOAT, GL_FALSE, 0, quad);
		glVertexAttribPointer(WMShaderAttributeTexCoord0, 2, GL_FLOAT, GL_FALSE, 0, quadTCs);
		
		
		int textureUniformLocation = [shader uniformLocationForName:@"texture"];
		if (rttTexture && textureUniformLocation != -1) {
			glBindTexture(GL_TEXTURE_2D, [rttTexture name]);
		}
		
		MATRIX screenQuadTransform;
		MatrixIdentity(screenQuadTransform);
		
		int matrixUniform = [shader uniformLocationForName:@"modelViewProjectionMatrix"];
		if (matrixUniform != -1) {
			glUniformMatrix4fv(matrixUniform, 1, NO, screenQuadTransform.f);
		}
		
		GL_CHECK_ERROR;
		
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		
		[rttTexture discardData];
		
		GL_CHECK_ERROR;
	}
}
@end
