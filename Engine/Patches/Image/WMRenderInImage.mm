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
#import "WMRenderObject.h"

//use for +cameraMatrixWithRect:
#import "WMEngine.h"

@implementation WMRenderInImage {	
	BOOL useDepthBuffer;
}

+ (NSString *)category;
{
    return WMPatchCategoryImage;
}

+ (void)load;
{
	@autoreleasepool {
		[self registerPatchClass];
	}
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

- (void)renderObject:(WMRenderObject *)inObject withTransform:(GLKMatrix4)inMatrix inContext:(WMEAGLContext *)inContext;
{
	[inObject postmultiplyTransform:inMatrix];
	[inContext renderObject:inObject];
}

- (BOOL)execute:(WMEAGLContext *)context time:(double)time arguments:(NSDictionary *)args;
{
	if (!inputObject1.object && !inputObject2.object && !inputObject3.object && !inputObject4.object) {
		outputImage.image = nil;
		return YES;
	}
	
	CGSize outputSize = [[args objectForKey:WMEngineArgumentsOutputDimensionsKey] CGSizeValue];
	
	unsigned int renderWidth = inputWidth.index;
	unsigned int renderHeight = inputHeight.index;
	if (renderWidth == 0) {
		renderWidth = (NSUInteger)outputSize.width;
	}
	if (renderHeight == 0) {
		renderHeight = (NSUInteger)outputSize.height;
	}

	if (renderWidth == 0 || renderHeight == 0) {
		//Can't render because we have no idea about output size
		DLog(@"unable to render because we couldn't infer RII size from bound framebuffer.");
		return YES;
	}
	
	WMTexture2D *texture = [context renderToTextureWithWidth:renderWidth height:renderHeight depthBufferDepth:useDepthBuffer ? GL_DEPTH_COMPONENT16 : 0 block:^{
		GLKMatrix4 transform = [WMEngine cameraMatrixWithRect:(CGRect){0, 0, renderWidth, renderHeight}];

		[context clearToColor:inputClearColor.v];
		[context clearDepth];
		
		if (inputObject1.object) {
			[self renderObject:inputObject1.object withTransform:transform inContext:context];
		}
		if (inputObject2.object) {
			[self renderObject:inputObject2.object withTransform:transform inContext:context];
		}
		if (inputObject3.object) {
			[self renderObject:inputObject3.object withTransform:transform inContext:context];
		}
		if (inputObject4.object) {
			[self renderObject:inputObject4.object withTransform:transform inContext:context];
		}

	}];

	outputImage.image = texture;
	
	return YES;
}

@end
