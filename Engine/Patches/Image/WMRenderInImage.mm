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

//use for +cameraMatrixWithRect:
#import "WMEngine.h"

@implementation WMRenderInImage

+ (NSString *)category;
{
    return WMPatchCategoryRender;
}

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
									  contentSize:(CGSize){renderWidth, renderHeight}
										orientation:UIImageOrientationUp];
		framebuffer = [[WMFramebuffer alloc] initWithTexture:texture depthBufferDepth:useDepthBuffer ? GL_DEPTH_COMPONENT16 : 0];
		
		if (!texture || !framebuffer) {
			return NO;
		}
		NSLog(@"Created framebuffer: %@", framebuffer);
	}
	
	context.modelViewMatrix = [WMEngine cameraMatrixWithRect:(CGRect){0, 0, renderWidth, renderHeight}];
	context.boundFramebuffer = framebuffer;
	glViewport(0, 0, renderWidth, renderHeight);
	outputImage.image = texture;
	
	return YES;
}

@end
