//
//  WMImageOrientation.m
//  Take
//
//  Created by Andrew Pouliot on 8/1/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import "WMImageOrientation.h"

#import "WMTexture2D.h"

@implementation WMImageOrientation

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
		_outputOrientation.index = _inputImage.image.orientation;
	} else {
		_outputOrientation.index = UIImageOrientationUp;
	}
	
	return YES;
}

@end
