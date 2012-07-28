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
		_outputSize.v = GLKVector2FromCGSize(_inputImage.image.contentSize);
		_outputSizeInv.v = (GLKVector2){1.0 / _outputSize.v.x, 1.0 / _outputSize.v.y};
	} else {
		_outputSize.v = (GLKVector2){};
		_outputSizeInv.v = (GLKVector2){};
	}
	return YES;
}


@end
