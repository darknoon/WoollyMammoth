//
//  GLKMathUICompatibility.h
//  WMGraph
//
//  Created by Andrew Pouliot on 12/22/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (GLKVectorValue)

//Assume rgba color
- (GLKVector4)componentsAsRGBAGLKVector4;

//Assume rgb color
- (GLKVector3)componentsAsRGBGLKVector3;

//Assume <brightness, alpha> color space
- (GLKVector2)componentsAsRGBGLKVector2;

//Just single component, hopefully
- (float)brightnessComponent;

@end


