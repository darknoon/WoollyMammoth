//
//  WMRenderInImage.m
//  Particulon
//
//  Created by Andrew Pouliot on 4/24/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMRenderInImage.h"

#import "WMFramebuffer.h"
#import "WMTexture2D.h"
#import "WMEAGLContext.h"

#import "Matrix.h"

@implementation WMRenderInImage

+ (void)load;
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self registerToRepresentClassNames:[NSSet setWithObject:@"QCRenderInImage"]];
	[pool drain];
}

- (id)initWithPlistRepresentation:(id)inPlist;
{
	self = [super initWithPlistRepresentation:inPlist];
	if (!self) return nil;
	
	useDepthBuffer = NO;
	
	return self;
}

- (WMPatchExecutionMode)executionMode;
{
	return kWMPatchExecutionModeRII;
}

- (MATRIX)cameraMatrixWithRect:(CGRect)inBounds;
{
	MATRIX cameraMatrix;
	//TODO: move this state setting to WMEAGLContext
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
	
	return cameraMatrix;
}


- (BOOL)execute:(WMEAGLContext *)context time:(double)time arguments:(NSDictionary *)args;
{
	NSUInteger renderWidth = inputWidth.index;
	NSUInteger renderHeight = inputHeight.index;
	if (renderWidth == 0) {
		renderWidth = context.boundFramebuffer.framebufferWidth;
	}
	if (renderHeight == 0) {
		renderHeight = context.boundFramebuffer.framebufferHeight;
	}
	
	if (!framebuffer || framebuffer.framebufferWidth != renderWidth || framebuffer.framebufferHeight != renderHeight) {
		//Re-create framebuffer and texture
		[texture release];
		[framebuffer release];
		
		texture = [[WMTexture2D alloc] initWithData:NULL
									  pixelFormat:kWMTexture2DPixelFormat_RGBA8888
									   pixelsWide:renderWidth
									   pixelsHigh:renderHeight
									  contentSize:(CGSize){renderWidth, renderHeight}];
		framebuffer = [[WMFramebuffer alloc] initWithTexture:texture depthBufferDepth:useDepthBuffer ? GL_DEPTH_COMPONENT16 : 0];
		
		if (!texture || !framebuffer) {
			return NO;
		}
		NSLog(@"Created framebuffer: %@", framebuffer);
	}
	
	MATRIX m = [self cameraMatrixWithRect:(CGRect){0, 0, renderWidth, renderHeight}];
	[context setModelViewMatrix:m.f];
	context.boundFramebuffer = framebuffer;
	glViewport(0, 0, renderWidth, renderHeight);
	outputImage.image = texture;
	
	return YES;
}

@end
