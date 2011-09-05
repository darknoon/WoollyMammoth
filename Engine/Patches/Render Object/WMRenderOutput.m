//
//  Created by Andrew Pouliot on 7/27/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMRenderOutput.h"

#import "WMEAGLContext.h"

@implementation WMRenderOutput

+ (NSString *)category;
{
    return WMPatchCategoryUnknown;
}

+ (void)load;
{
	@autoreleasepool {
		[self registerPatchClass];
	}
}

- (BOOL)execute:(WMEAGLContext *)context time:(double)time arguments:(NSDictionary *)args;
{
	if (inputRenderable1.object) {
		[context renderObject:inputRenderable1.object];
	}
	if (inputRenderable2.object) {
		[context renderObject:inputRenderable2.object];
	}
	if (inputRenderable3.object) {
		[context renderObject:inputRenderable3.object];
	}
	if (inputRenderable4.object) {
		[context renderObject:inputRenderable4.object];
	}
	
	return YES;
}

@end
