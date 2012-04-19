//
//  WMDefinesMac.h
//  PizzaEngine
//
//  Created by Andrew Pouliot on 4/18/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//


#if !TARGET_OS_IPHONE


typedef enum {
    UIImageOrientationUp,            // default orientation
    UIImageOrientationDown,          // 180 deg rotation
    UIImageOrientationLeft,          // 90 deg CCW
    UIImageOrientationRight,         // 90 deg CW
    UIImageOrientationUpMirrored,    // as above but image mirrored along other axis. horizontal flip
    UIImageOrientationDownMirrored,  // horizontal flip
    UIImageOrientationLeftMirrored,  // vertical flip
    UIImageOrientationRightMirrored, // vertical flip
} UIImageOrientation;


#endif
