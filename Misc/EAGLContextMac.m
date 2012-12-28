//
//  EAGLContextMac.m
//  WoollyEditor
//
//  Created by Andrew Pouliot on 10/27/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "EAGLContextMac.h"

NSString *const EAGLMacThreadDictionaryKey = @"com.darknoon.EAGLMacContext";

@interface EAGLSharegroup : NSObject
@property (nonatomic, weak) NSOpenGLContext *context;

@end

@implementation EAGLSharegroup
@synthesize context = _context;
@end



@implementation EAGLContext

- (id)initWithOpenGLContext:(NSOpenGLContext *)context;
{
	self = [self init];
	if (!self) return nil;
	//TODO: check context compatibility
	
	_openGLContext = context;
	
	return self;
}

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
//		// Must specify the 3.2 Core Profile to use OpenGL 3.2
//		NSOpenGLPFAOpenGLProfile,
//		NSOpenGLProfileVersion3_2Core,
		0
	};
	
	
	NSOpenGLPixelFormat *pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
	
	if (!pf) {
		NSLog(@"No OpenGL pixel format");
		return nil;
	}
    
	NSOpenGLContext *context = [[NSOpenGLContext alloc] initWithFormat:pf shareContext:sharegroup.context];
	if (!context) return nil;
	self = [self initWithOpenGLContext:context];

	_sharegroup = sharegroup;
	if (!_sharegroup) {
		_sharegroup = [[EAGLSharegroup alloc] init];
		_sharegroup.context = self.openGLContext;
	}
	
	_API = inSimulatedAPI;
	
	return self;
}

+ (BOOL)setCurrentContext:(EAGLContext *)context;
{
	if (context) {
		[context.openGLContext makeCurrentContext];
#warning excessive
		ZAssert([NSOpenGLContext currentContext] == context.openGLContext, @"Did not set context");
		[[[NSThread currentThread] threadDictionary] setObject:context forKey:EAGLMacThreadDictionaryKey];
	} else {
		[NSOpenGLContext clearCurrentContext];
	}
	return YES;
}

+ (EAGLContext *)currentContext;
{
	EAGLContext *currentContext = [[[NSThread currentThread] threadDictionary] objectForKey:EAGLMacThreadDictionaryKey];
	ZAssert([NSOpenGLContext currentContext] == currentContext.openGLContext, @"Wrong context set!");
	return currentContext;
}

@end

