//
//  EAGLContextMac.m
//  WoollyEditor
//
//  Created by Andrew Pouliot on 10/27/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "EAGLContextMac.h"


@implementation EAGLContext

@synthesize API = simulatedAPI;

- (id)initWithAPI:(int)inSimulatedAPI;
{
	NSOpenGLPixelFormatAttribute attrs[] =
	{
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFADepthSize, 32,
		0
	};
	
	NSOpenGLPixelFormat *format = [[[NSOpenGLPixelFormat alloc] initWithAttributes:attrs] autorelease];
	self = [super initWithFormat:format shareContext:NULL];
	if (!self) return nil;
	
	simulatedAPI = inSimulatedAPI;
	
	return self;
}

+ (BOOL)setCurrentContext:(EAGLContext *)inCurrentContext;
{
	[inCurrentContext makeCurrentContext];
	return YES;
}

+ (EAGLContext *)currentContext;
{
	return [EAGLContext currentContext];
}

@end
