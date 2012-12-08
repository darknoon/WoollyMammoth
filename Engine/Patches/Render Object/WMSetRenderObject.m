//
//  WMSetRenderObject.m
//  WMEdit
//
//  Created by Andrew Pouliot on 10/15/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import "WMSetRenderObject.h"

#import "WMRenderObject.h"
#import "WMPorts.h"

@implementation WMSetRenderObject {
	WMRenderObject *object;
}

@synthesize inputObject;
@synthesize outputObject;

@synthesize inputVertices;
@synthesize inputIndices;

+ (NSString *)category;
{
    return WMPatchCategoryUtil;
}

+ (void)load;
{
	@autoreleasepool {
		[self registerPatchClass];
	}
}

- (BOOL)execute:(WMEAGLContext *)context time:(double)time arguments:(NSDictionary *)args;
{
	if (inputObject.object) {
		object = inputObject.object;
	} else if (inputVertices.object) {
		object = [[WMRenderObject alloc] init];
	} else {
		object = nil;
	}
	
	if (object) {
		if (inputVertices.object) object.vertexBuffer = inputVertices.object;
		if (inputIndices.object) object.indexBuffer = inputIndices.object;
		//TODO: do some sort of connection logic here
		object.renderBlendState = DNGLStateBlendEnabled;
		object.renderDepthState = 0;
		object.renderType = GL_TRIANGLES;
	}
	
	outputObject.object = object;
	
	return YES;
}

@end
