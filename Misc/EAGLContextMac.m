//
//  EAGLContextMac.m
//  WoollyEditor
//
//  Created by Andrew Pouliot on 10/27/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "EAGLContextMac.h"


@interface EAGLSharegroup : NSObject
@property (nonatomic, weak) NSOpenGLContext *context;

@end

@implementation EAGLSharegroup
@synthesize context = _context;
@end



@implementation EAGLContext

@synthesize API = _API;
@synthesize sharegroup = _sharegroup;

- (id)initWithAPI:(int)inSimulatedAPI;
{
	return [self initWithAPI:inSimulatedAPI sharegroup:nil];
}

- (id)initWithAPI:(int)inSimulatedAPI sharegroup:(EAGLSharegroup *)sharegroup;
{
    NSOpenGLPixelFormatAttribute attrs[] =
	{
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFADepthSize, 24,
		// Must specify the 3.2 Core Profile to use OpenGL 3.2
		NSOpenGLPFAOpenGLProfile,
		NSOpenGLProfileVersion3_2Core,
		0
	};
	
	
	NSOpenGLPixelFormat *pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
	
	if (!pf)
	{
		NSLog(@"No OpenGL pixel format");
	}
    
	self = [super initWithFormat:pf shareContext:sharegroup.context];
	if (!self) return nil;

	_sharegroup = sharegroup;
	if (!_sharegroup) {
		_sharegroup = [[EAGLSharegroup alloc] init];
		_sharegroup.context = self;
	}
	
	_API = inSimulatedAPI;
	
	return self;
}

+ (BOOL)setCurrentContext:(EAGLContext *)context;
{
	[context makeCurrentContext];
	return YES;
}

+ (EAGLContext *)currentContext;
{
	return (EAGLContext *)[NSOpenGLContext currentContext];
}

@end

