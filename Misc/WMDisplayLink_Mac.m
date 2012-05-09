//
//  WMDisplayLinkMac.m
//  PizzaEngine
//
//  Created by Andrew Pouliot on 4/26/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import "WMDisplayLink.h"

#import <QuartzCore/CVDisplayLink.h>

static CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp* now, const CVTimeStamp* outputTime, CVOptionFlags flagsIn, CVOptionFlags* flagsOut, void* displayLinkContext);

@implementation WMDisplayLink {
	dispatch_queue_t _targetQueue;
	CVDisplayLinkRef _displayLink;
	void (^_callback)(NSTimeInterval t, NSTimeInterval dt);
}

- (id)initWithTargetQueue:(dispatch_queue_t)queue callback:(void (^)(NSTimeInterval t, NSTimeInterval dt))callback;
{
	if (!queue || !callback) return nil;
	
	self = [super init];
	if (!self) return nil;
	
	_targetQueue = queue;
	dispatch_retain(queue);

	_callback = [callback copy];
	
	// Create a display link capable of being used with all active displays
	CVDisplayLinkCreateWithActiveCGDisplays(&_displayLink);
	if (!_displayLink) return nil;
	
	// Set the renderer output callback function
	CVDisplayLinkSetOutputCallback(_displayLink, &MyDisplayLinkCallback, (__bridge void *)self);
	
	CVDisplayLinkStart(_displayLink);
		
	return self;
}

- (void)dealloc
{
	CVDisplayLinkRelease(_displayLink);
	_displayLink = nil;

	dispatch_release(_targetQueue);
}

- (void)_displayLinkCallback:(CVDisplayLinkRef)displayLink currentTime:(NSTimeInterval)currentTime outputTime:(NSTimeInterval)outputTime;
{
	dispatch_sync(_targetQueue, ^{
		_callback(currentTime, 1.0/60.0);
	});
}

@end


// This is the renderer output callback function
static CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp* now, const CVTimeStamp* outputTime, CVOptionFlags flagsIn, CVOptionFlags* flagsOut, void* displayLinkContext)
{
	NSTimeInterval nowSeconds = now->hostTime / (double)now->videoTimeScale;
	NSTimeInterval ouputTimeSeconds = outputTime->hostTime / (double)outputTime->videoTimeScale;
	[(__bridge WMDisplayLink*)displayLinkContext _displayLinkCallback:displayLink currentTime:nowSeconds outputTime:ouputTimeSeconds];
    return kCVReturnSuccess;
}
