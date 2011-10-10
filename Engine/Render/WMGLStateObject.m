//
//  WMGLStateObject.m
//  WMEdit
//
//  Created by Andrew Pouliot on 10/9/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import "WMGLStateObject.h"
#import "WMGLStateObject_WMEAGLContext_Private.h"

#import "WMEAGLContext.h"

@implementation WMGLStateObject
@synthesize context;

- (id)init;
{
	self = [super init];
	if (!self) return nil;
	
	self.context = (WMEAGLContext *)[WMEAGLContext currentContext];
	
	return self;
}

- (void)deleteInternalState;
{
	//Default implementation does nothing. Override this to clean up your state on deallocation.
}

- (void)dealloc;
{
	//If the gl context we were created in still exists, then delete all internal state for the current object
	if (context) {
		[WMEAGLContext setCurrentContext:context];
		[self deleteInternalState];
	}
}

@end
