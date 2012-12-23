//
//  GLKMathCACompatibility.c
//  WMEdit
//
//  Created by Andrew Pouliot on 12/22/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import <GLKit/GLKMath.h>
#import <QuartzCore/QuartzCore.h>

static __inline__ CATransform3D CATransform3DFromGLKMatrix4(GLKMatrix4 t) {
	return (CATransform3D){
		t.m00, t.m01, t.m02, t.m03,
		t.m10, t.m11, t.m12, t.m13,
		t.m20, t.m21, t.m22, t.m23,
		t.m30, t.m31, t.m32, t.m33,
	};
}

static __inline__ GLKMatrix4 GLKMatrix4FromCATransform3D(CATransform3D t) {
	return (GLKMatrix4){
		t.m11, t.m12, t.m13, t.m14,
		t.m21, t.m22, t.m23, t.m24,
		t.m31, t.m32, t.m33, t.m34,
		t.m41, t.m42, t.m43, t.m44,
	};
};
