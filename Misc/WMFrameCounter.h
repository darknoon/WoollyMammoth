//
//  WMFrameCounter.h
//  WMLite
//
//  Created by Andrew Pouliot on 4/26/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

/** A simple FPS counter. */
@interface WMFrameCounter : NSObject

/** @abstract How often the frame-per-second count is updated */
@property (nonatomic) double updateInterval;

/** @abstract The number frames per second over the most recent updateInterval. */
@property (nonatomic, readonly) double fps;

/** @abstract The most recent duration passed into -recordFrameWithTime:duration: . */
@property (nonatomic, readonly) double lastDuration;

/** @abstract Record a frame
 @param t The time at which the frame occurred. Use CACurrentMediaTime() or similar
 @param duration The time it took to render the frame. */

- (void)recordFrameWithTime:(NSTimeInterval)t duration:(NSTimeInterval)duration;

@end
