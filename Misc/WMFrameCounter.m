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
	double lastFPSUpdate;
	NSUInteger framesSinceLastFPSUpdate;
	NSTimeInterval lastFrameEndTime;
	
}
@synthesize fps = _fps;
@synthesize updateInterval = _updateInterval;
- (id)init;
{
    self = [super init];
    if (!self) return nil;
	
	_updateInterval = 1.0;
    
    return self;
}



- (void)recordFrameWithTime:(NSTimeInterval)t duration:(NSTimeInterval)duration;
{
	lastFrameEndTime = t;
	
	framesSinceLastFPSUpdate++;
	if (t - lastFPSUpdate > _updateInterval) {
		_fps = framesSinceLastFPSUpdate;
		framesSinceLastFPSUpdate = 0;
		
		lastFPSUpdate = t;
	}
}

@end
