//
//  WMImageSize.m
//  WMEdit
//
//  Created by Andrew Pouliot on 7/27/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import "WMImageSize.h"

#import "WMTexture2D.h"

@implementation WMImageSize

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

- (BOOL)execute:(WMEAGLContext *)context time:(double)time arguments:(NSDictionary *)args;
{
	if (_inputImage.image) {
		CGSize imageSize =_inputImage.image.contentSize;
		_outputWidth.index = imageSize.width;
		_outputHeight.index = imageSize.width;
		_outputSizeInv.v = (GLKVector2){1.0 / imageSize.width, 1.0 / imageSize.height};
	} else {
		_outputWidth.index = 0;
		_outputHeight.index = 0;
		_outputSizeInv.v = (GLKVector2){};
	}
	return YES;
}


@end
