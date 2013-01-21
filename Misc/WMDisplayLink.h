//
//  WMDisplayLink.h
//  WMLite
//
//  Created by Andrew Pouliot on 4/26/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>


/*!
 Presents a unified display-link API on Mac and iOS.
 
 In the future, the dispatch-based API may change to a runloop one.
 On iOS, this uses CADisplayLink, whereas on Mac it uses CVDisplayLink.

 The display link targets the main screen.
 */
@interface WMDisplayLink : NSObject

/*!
 @param queue The queue on which the callback will be executed. Pass dispatch_get_main_queue() to use the main thread.

 @param callback A block to run on the target queue.
 
 The paramater t will be an increasing number that can be used to drive animations, etc. dt is the expected time between callbacks.
 @discussion The display link is scheduled immediately after this method returns.
 */
- (id)initWithTargetQueue:(dispatch_queue_t)queue callback:(void (^)(NSTimeInterval t, NSTimeInterval dt))callback;

- (void)invalidate;

@end
