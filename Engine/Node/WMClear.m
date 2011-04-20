//
//  WMClear.m
//  Particulon
//
//  Created by Andrew Pouliot on 4/19/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMClear.h"

#import "WMColorPort.h"
#import "DNEAGLContext.h"

@implementation WMClear

+ (void)load;
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self registerToRepresentClassNames:[NSSet setWithObject:@"QCClear"]];
	[pool drain];
}

- (id)initWithPlistRepresentation:(id)inPlist;
{
	self = [super initWithPlistRepresentation:inPlist];
	if (!self) return nil;
	
	return self;
}

- (BOOL)execute:(DNEAGLContext *)inContext time:(CFTimeInterval)time arguments:(NSDictionary *)args;
{
	glClearColor(inputColor.red, inputColor.green, inputColor.blue, inputColor.alpha);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	return YES;
}

@end
