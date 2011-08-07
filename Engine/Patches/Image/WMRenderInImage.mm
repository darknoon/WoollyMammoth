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
    return WMPatchCategoryImage;
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
	if (!inputObject1.object && !inputObject2.object && !inputObject3.object && !inputObject4.object) {
		outputImage.image = nil;
		return YES;
	}
	
	//If no size is specified use the width / height of the current framebuffer (presumably the size of main output)
	//TODO: more strictly define this behavior and pass through
	WMFramebuffer *oldFramebuffer = context.boundFramebuffer;
	NSUInteger renderWidth = inputWidth.index;
	NSUInteger renderHeight = inputHeight.index;
	if (renderWidth == 0) {
		renderWidth = oldFramebuffer.framebufferWidth;
	}
	if (renderHeight == 0) {
		renderHeight = oldFramebuffer.framebufferHeight;
	}
	
	if (renderWidth == 0 || renderHeight == 0) {
		//Can't render because we have no idea about output size
		NSLog(@"unable to render because we couldn't infer RII size from bound framebuffer.");
		return YES;
	}
	
	//Recreate texture each frame (fix me!)
	[texture release];
	texture = [[WMTexture2D alloc] initWithData:NULL
									pixelFormat:kWMTexture2DPixelFormat_RGBA8888
									 pixelsWide:renderWidth
									 pixelsHigh:renderHeight
									contentSize:(CGSize){renderWidth, renderHeight}
									orientation:UIImageOrientationUpMirrored];
	
	if (!framebuffer || framebuffer.framebufferWidth != renderWidth || framebuffer.framebufferHeight != renderHeight) {
		//Re-create framebuffer and texture
		[framebuffer release];
		
		framebuffer = [[WMFramebuffer alloc] initWithTexture:texture depthBufferDepth:useDepthBuffer ? GL_DEPTH_COMPONENT16 : 0];
		
		if (!texture || !framebuffer) {
			return NO;
		}
		NSLog(@"Created framebuffer: %@", framebuffer);
	}
	
	[framebuffer setColorAttachmentWithTexture:texture];

	context.modelViewMatrix = [WMEngine cameraMatrixWithRect:(CGRect){0, 0, renderWidth, renderHeight}];
	context.boundFramebuffer = framebuffer;
	
	GLKVector4 clearColor = inputClearColor.v;
	
	glClearColor(clearColor.r, clearColor.g, clearColor.b, clearColor.a);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	if (inputObject1.object) [context renderObject:inputObject1.object];
	if (inputObject2.object) [context renderObject:inputObject2.object];
	if (inputObject3.object) [context renderObject:inputObject3.object];
	if (inputObject4.object) [context renderObject:inputObject4.object];
	
	outputImage.image = texture;
	
	context.boundFramebuffer = oldFramebuffer;
	
	return YES;
}

@end
