//
//  WMDisplayLinkMac.h
//  PizzaEngine
//
//  Created by Andrew Pouliot on 4/26/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WMDisplayLink : NSObject

//Scheduled immediately after this method returns
//Pass dispatch_get_main_queue() to use on the main thread
- (id)initWithTargetQueue:(dispatch_queue_t)queue callback:(void (^)(NSTimeInterval t, NSTimeInterval dt))callback;

- (void)invalidate;

@end
