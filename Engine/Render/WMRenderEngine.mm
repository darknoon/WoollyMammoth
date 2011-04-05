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
		
	context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!context) {
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
		NSLog(@"Falling back to ES 1 context because we could not create ES 2 context.");
    }
    if (!context) {
        NSLog(@"Failed to create ES context");
	}	else if (![EAGLContext setCurrentContext:context]) {
        NSLog(@"Failed to set ES context current");
	}
		
	[EAGLContext setCurrentContext:context];
	
	glState = [[DNGLState alloc] init];
		
	return self;
}

- (void) dealloc
{
	// Tear down context.
    if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];
	[context release];
	[glState release];
	
	[super dealloc];
}


- (void)setCameraMatrixWithRect:(CGRect)inBounds;
{
	glCullFace(GL_BACK);
	
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
		[renderable drawWithTransform:transform API:context.API glState:glState];
		// NSLog(@"after %@: %@", inObject.notes, glState);
	}
	
	for (WMGameObject *object in inObject.children) {
		[self drawFrameRecursive:object transform:transform];
	}
}

- (void)drawFrameInRect:(CGRect)inBounds;
{
	[self setCameraMatrixWithRect:inBounds];
	
    glClearColor(0.5f, 0.6f, 0.6f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
		
	[self drawFrameRecursive:engine.rootObject transform:cameraMatrix];
	
	GL_CHECK_ERROR;
		
}
@end
