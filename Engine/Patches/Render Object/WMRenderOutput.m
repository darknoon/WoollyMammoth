//
//  Created by Andrew Pouliot on 7/27/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMRenderOutput.h"

#import "WMEAGLContext.h"

#import "WMEngine.h"
#import "WMRenderObject.h"


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

- (void)renderObject:(WMRenderObject *)inObject withTransform:(GLKMatrix4)inMatrix inContext:(WMEAGLContext *)inContext;
{
	[inObject postmultiplyTransform:inMatrix];
	[inContext renderObject:inObject];
}

- (BOOL)execute:(WMEAGLContext *)context time:(double)time arguments:(NSDictionary *)args;
{
	CGSize outputSize = [[args objectForKey:WMEngineArgumentsOutputDimensionsKey] CGSizeValue];
	GLKMatrix4 transform = cameraMatrixForRect((CGRect){.size = outputSize});
	
	if (inputRenderable1.object) {
		[self renderObject:inputRenderable1.object withTransform:transform inContext:context];
	}
	if (inputRenderable2.object) {
		[self renderObject:inputRenderable2.object withTransform:transform inContext:context];
	}
	if (inputRenderable3.object) {
		[self renderObject:inputRenderable3.object withTransform:transform inContext:context];
	}
	if (inputRenderable4.object) {
		[self renderObject:inputRenderable4.object withTransform:transform inContext:context];
	}
	
	return YES;
}

@end
