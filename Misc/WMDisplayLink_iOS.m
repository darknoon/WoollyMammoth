//
//  WMDisplayLink_iOS.m
//  WMLite
//
//  Created by Andrew Pouliot on 4/26/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import "WMDisplayLink.h"

#import <QuartzCore/QuartzCore.h>

@implementation WMDisplayLink {
	CADisplayLink *_displayLink;
	dispatch_queue_t _targetQueue;
	void (^_callback)(NSTimeInterval t, NSTimeInterval dt);
	
	NSThread *_runloopThread;
}

- (id)initWithTargetQueue:(dispatch_queue_t)queue callback:(void (^)(NSTimeInterval t, NSTimeInterval dt))callback;
{
	if (!queue || !callback) return nil;
	
	self = [super init];
	if (!self) return nil;
	
	_targetQueue = queue;
	_callback = [callback copy];
	
	_displayLink = [[UIScreen mainScreen] displayLinkWithTarget:self selector:@selector(_displayLinkCallback:)];
	
	if (queue != dispatch_get_main_queue()) {
		_runloopThread = [[NSThread alloc] initWithTarget:self selector:@selector(_runDisplayLinkThread) object:nil];
		
		[_runloopThread start];
	} else {
		[_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
	}
	
	return self;
}

- (void)dealloc
{
	[self invalidate];
}

- (void)_runDisplayLinkThread;
{
	//Create a runloop for this thread
	NSRunLoop *rl = [NSRunLoop currentRunLoop];
	//Add the display link to this runloop
	[_displayLink addToRunLoop:rl forMode:NSRunLoopCommonModes];
	//Run it
	[rl run];
}

- (void)_displayLinkCallback:(CADisplayLink *)displayLink;
{
	//dispatch_sync to ensure that callbacks don't back up in the queue
	if (dispatch_get_current_queue() != _targetQueue) {
		dispatch_sync(_targetQueue, ^{
			_callback(displayLink.timestamp, displayLink.duration);
		});
	} else {
		_callback(displayLink.timestamp, displayLink.duration);
	}
}

- (void)invalidate;
{
	[_displayLink invalidate];
	_displayLink = nil;
}

@end
