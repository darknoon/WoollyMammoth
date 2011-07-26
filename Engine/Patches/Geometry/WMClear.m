//
//  WMClear.m
//  Particulon
//
//  Created by Andrew Pouliot on 4/19/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMClear.h"

#import "WMColorPort.h"
#import "WMEAGLContext.h"
#import "WMFramebuffer.h"

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

+ (id)defaultValueForInputPortKey:(NSString *)inKey;
{
	if ([inKey isEqualToString:@"inputColor"]) {
		return [NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithFloat:0.2f], @"red",
				[NSNumber numberWithFloat:0.2f], @"green",
				[NSNumber numberWithFloat:0.2f], @"blue",
				[NSNumber numberWithFloat:1.0f], @"alpha",
				nil];
	}
	return nil;
}

- (BOOL)execute:(WMEAGLContext *)inContext time:(CFTimeInterval)time arguments:(NSDictionary *)args;
{
	GLKVector4 color = inputColor.v;
	glClearColor(color.r, color.g, color.b, color.a);
	if (inContext.boundFramebuffer.hasDepthbuffer) {
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	} else {
		glClear(GL_COLOR_BUFFER_BIT);
	}
	return YES;
}

@end
