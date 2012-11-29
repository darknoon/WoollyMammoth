//
//  NSValue+GLKVector.h
//  WMEdit
//
//  Created by Andrew Pouliot on 7/28/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <GLKit/GLKMath.h>

//TODO: rename this file

@interface NSValue (GLKVector)

- (id)initWithGLKVector4:(GLKVector4)v;
- (id)initWithGLKVector3:(GLKVector3)v;
- (id)initWithGLKVector2:(GLKVector2)v;

+ (id)valueWithGLKVector4:(GLKVector4)v;
+ (id)valueWithGLKVector3:(GLKVector3)v;
+ (id)valueWithGLKVector2:(GLKVector2)v;

//If the NSValue contains a GLKVector, then any of these values are valid. Otherwise, they return the respective zero vector.
- (BOOL)containsGLKVector;

- (GLKVector4)GLKVector4Value;
- (GLKVector3)GLKVector3Value;
- (GLKVector2)GLKVector2Value;

@end


@interface NSValue (GLKMatrix)

//TODO: the other matrix sizes, with implicit conversion routines

- (id)initWithGLKMatrix4:(GLKMatrix4)matrix;

+ (id)valueWithGLKMatrix4:(GLKMatrix4)matrix;

- (BOOL)containsGLKMatrix4;

- (GLKMatrix4)GLKMatrix4Value;

@end