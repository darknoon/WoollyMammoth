//
//  WMSimpleCamera.h
//  SmoothHex
//
//  Created by Andrew Pouliot on 2/14/13.
//  Copyright (c) 2013 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WMTexture2D;
@class WMEAGLContext;

@interface WMSimpleCamera : NSObject

- (id)initWithTargetQueue:(dispatch_queue_t)queue context:(WMEAGLContext *)context captureBlock:(void (^)(WMTexture2D *texture))block;

- (void)beginCapture;
- (void)stopCapture;

@end
