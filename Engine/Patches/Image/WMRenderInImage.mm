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
#import "WMRenderCommon.h"
#import "WMTransforms.h"
//use to get the default render size argument
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

+ (id)defaultValueForInputPortKey:(NSString *)inKey;
{
	if ([inKey isEqualToString:KVC([WMRenderInImage new], inputOrientation)]) {
		return @(UIImageOrientationUp);
	}
	return [super defaultValueForInputPortKey:inKey];
}

- (id)initWithPlistRepresentation:(id)inPlist;
{
	self = [super initWithPlistRepresentation:inPlist];
	if (!self) return nil;
	
	useDepthBuffer = NO;
	
	return self;
}

- (void)renderObject:(WMRenderObject *)inObject withTransform:(GLKMatrix4)inMatrix inContext:(WMEAGLContext *)inContext;
{
	[inObject postmultiplyTransform:inMatrix];
	[inContext renderObject:inObject];
}


- (BOOL)execute:(WMEAGLContext *)context time:(double)time arguments:(NSDictionary *)args;
{
	if (!_inputObject1.object && !_inputObject2.object && !_inputObject3.object && !_inputObject4.object) {
		_outputImage.image = nil;
		return YES;
	}
	
	CGSize outputSize = [[args objectForKey:WMEngineArgumentsOutputDimensionsKey] CGSizeValue];
	
	unsigned int renderWidth = _inputWidth.index;
	unsigned int renderHeight = _inputHeight.index;
	if (renderWidth == 0) {
		renderWidth = (unsigned int)outputSize.width;
	}
	if (renderHeight == 0) {
		renderHeight = (unsigned int)outputSize.height;
	}

	if (renderWidth == 0 || renderHeight == 0) {
		//Can't render because we have no idea about output size
		DLog(@"unable to render because we couldn't infer RII size from bound framebuffer.");
		return YES;
	}
	
	UIImageOrientation outputOrientation = (UIImageOrientation)_inputOrientation.index;
	GLKMatrix4 transform = transformForRenderingInOrientation(outputOrientation, renderWidth, renderHeight);
	
	WMTexture2D *texture = [context renderToTextureWithWidth:renderWidth height:renderHeight depthBufferDepth:useDepthBuffer ? GL_DEPTH_COMPONENT16 : 0 block:^{

		[context clearToColor:_inputClearColor.v];
		[context clearDepth];
		
		
		if (_inputObject1.object) {
			[self renderObject:_inputObject1.object withTransform:transform inContext:context];
		}
		if (_inputObject2.object) {
			[self renderObject:_inputObject2.object withTransform:transform inContext:context];
		}
		if (_inputObject3.object) {
			[self renderObject:_inputObject3.object withTransform:transform inContext:context];
		}
		if (_inputObject4.object) {
			[self renderObject:_inputObject4.object withTransform:transform inContext:context];
		}
	}];
	texture.orientation = (UIImageOrientation)_inputOrientation.index;
	_outputImage.image = texture;
	
	return YES;
}

@end
