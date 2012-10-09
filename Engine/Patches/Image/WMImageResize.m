//
//  WMImageResize.m
//  WMEdit
//
//  Created by Andrew Pouliot on 10/5/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import "WMImageResize.h"
#import "WMRenderObject+CreateWithGeometry.h"
#import "WMTexture2D.h"
@implementation WMImageResize

+ (void)load;
{
	@autoreleasepool {
		[self registerPatchClass];
	}
}

+ (NSString *)category;
{
    return WMPatchCategoryImage;
}

- (BOOL)execute:(WMEAGLContext *)context time:(double)time arguments:(NSDictionary *)args;
{
	WMTexture2D *result = nil;
	if (_inputImage.image) {
		int width = _inputImage.image.contentSize.width * _inputFactors.v.x, height = _inputImage.image.contentSize.height * _inputFactors.v.y;
		if (width > 0 && height > 0) {
			width  = MIN(width , context.maxTextureSize);
			height = MIN(height, context.maxTextureSize);
			
			result = [context renderToTextureWithWidth:width height:height block:^{
				
				WMRenderObject *ro = [WMRenderObject quadRenderObjectWithTexture2D:_inputImage.image uSubdivisions:2 vSubdivisions:2];
				[ro setValue:[NSValue valueWithGLKVector4:(GLKVector4){1,1,1,1}] forUniformWithName:@"color"];
				[ro setValue:_inputImage.image forUniformWithName:@"texture"];
				[context renderObject:ro];
			}];
		}
	}
	_outputImage.image = result;
	return YES;
}

@end
