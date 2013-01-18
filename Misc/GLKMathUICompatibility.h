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

/*!
 @category UIColor (GLKVectorValue)
 @abstract Convenience methods for retrieving the components of a color as a vector type. This is used internally by the WMEAGLContext to convert colors to vectors as inputs for shaders.
 */

@interface WMUIColorClass (GLKVectorValue)

/*!
 Retrieves the components of the reciever as a GLKVector4.
 Assumes an rgba color space.
 */
- (GLKVector4)componentsAsRGBAGLKVector4;

/*!
 Retrieves the components of the reciever as a GLKVector3.
 Assumes an rgb color space.
 */
- (GLKVector3)componentsAsRGBGLKVector3;

/*!
 Retrieves the components of the reciever as a GLKVector2.
 Assumes a <brightness, alpha> color space.
 */
- (GLKVector2)componentsAsRGBGLKVector2;

@end
