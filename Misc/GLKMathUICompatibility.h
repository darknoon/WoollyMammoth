//
//  GLKMathUICompatibility.h
//  WMGraph
//
//  Created by Andrew Pouliot on 12/22/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//


#ifndef WMUIColorClass

#if TARGET_OS_IPHONE
	#import <UIKit/UIKit.h>
	#define WMUIColorClass UIColor
#elif TARGET_OS_MAC
	#import <AppKit/AppKit.h>
	#define WMUIColorClass NSColor
#endif

#endif



@interface WMUIColorClass (GLKVectorValue)

//Assume rgba color
- (GLKVector4)componentsAsRGBAGLKVector4;

//Assume rgb color
- (GLKVector3)componentsAsRGBGLKVector3;

//Assume <brightness, alpha> color space
- (GLKVector2)componentsAsRGBGLKVector2;

@end
