//
//  WMFrameCounter.m
//  PizzaEngine
//
//  Created by Andrew Pouliot on 4/26/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import "WMFrameCounter.h"

@implementation WMFrameCounter {
	//Used to calculate actual FPS
	double _lastFPSUpdate;
	NSUInteger _framesSinceLastFPSUpdate;
	NSTimeInterval _lastFrameEndTime;
	
}
@synthesize fps = _fps;
@synthesize updateInterval = _updateInterval;
@synthesize lastDuration = _lastDuration;

- (id)init;
{
    self = [super init];
    if (!self) return nil;
	
	_updateInterval = 1.0;
    
    return self;
}

- (void)recordFrameWithTime:(NSTimeInterval)t duration:(NSTimeInterval)duration;
{
	_lastFrameEndTime = t;
	_lastDuration = duration;
	
	_framesSinceLastFPSUpdate++;
	if (t - _lastFPSUpdate > _updateInterval) {
		_fps = _framesSinceLastFPSUpdate;
		_framesSinceLastFPSUpdate = 0;
		
		_lastFPSUpdate = t;
	}
}

@end
