//
//  EAGLContextMac.h
//  WoollyEditor
//
//  Created by Andrew Pouliot on 10/27/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_MAC && !TARGET_OS_IPHONE

/* EAGL rendering API */
enum
{
	kEAGLRenderingAPIOpenGLES2 = 2
};
typedef int EAGLRenderingAPI;

@class EAGLSharegroup;

@interface EAGLContext : NSOpenGLContext {
	int simulatedAPI;
}

- (id)initWithAPI:(int)inSimulatedAPI;
- (id)initWithAPI:(int)inSimulatedAPI sharegroup:(EAGLSharegroup *)sharegroup;

@property (readonly) int API;

@property (readonly) EAGLSharegroup *sharegroup;

+ (BOOL)setCurrentContext:(EAGLContext *)inCurrentContext;
+ (EAGLContext *)currentContext;

@end


#endif