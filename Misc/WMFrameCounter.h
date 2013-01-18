//
//  WMFrameCounter.h
//  WMLite
//
//  Created by Andrew Pouliot on 4/26/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WMFrameCounter : NSObject

//How often the FPS is updated
@property (nonatomic) double updateInterval;

@property (nonatomic, readonly) double fps;
@property (nonatomic, readonly) double lastDuration;

- (void)recordFrameWithTime:(NSTimeInterval)t duration:(NSTimeInterval)duration;

@end
