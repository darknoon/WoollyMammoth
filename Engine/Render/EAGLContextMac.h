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
	kEAGLRenderingAPIOpenGLES1 = 1,
	kEAGLRenderingAPIOpenGLES2 = 2
};
typedef NSUInteger EAGLRenderingAPI;


@interface EAGLContext : NSOpenGLContext {
	int simulatedAPI;
}

- (id)initWithAPI:(int)inSimulatedAPI;

@property (readonly) int API;

+ (BOOL)setCurrentContext:(EAGLContext *)inCurrentContext;
+ (EAGLContext *)currentContext;

@end


#endif