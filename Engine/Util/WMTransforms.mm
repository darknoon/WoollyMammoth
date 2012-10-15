//
//  WMTransforms.w.c
//  Take
//
//  Created by Andrew Pouliot on 10/15/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import "WMTransforms.h"
#include "WMRenderCommon.h"

GLKMatrix4 cameraMatrixForRect(CGRect rect) {
	GLKMatrix4 cameraMatrix;
	
	const float near = 0.1;
	const float far = 10.0;
	
	const float aspectRatio = rect.size.height / rect.size.width;
	
	const float eyeZ = 3.0f; //rsl / nearZ
	
	const float scale = near / eyeZ;
	
	//GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(viewAngle, aspectRatio, near, far);
	GLKMatrix4 projectionMatrix = GLKMatrix4MakeFrustum(-scale, scale, -scale * aspectRatio, scale * aspectRatio, near, far);
	
	const GLKVector3 cameraPosition = {0, 0, eyeZ};
	const GLKVector3 cameraTarget = {0, 0, 0};
	const GLKVector3 upVec = {0, 1, 0};
	
	GLKMatrix4 viewMatrix = GLKMatrix4MakeLookAt(cameraPosition.x, cameraPosition.y, cameraPosition.z,
												 cameraTarget.x,   cameraTarget.y,   cameraTarget.z,
												 upVec.x,          upVec.y,          upVec.z);
	
	cameraMatrix = projectionMatrix * viewMatrix;

	return cameraMatrix;
}


GLKMatrix4 transformForRenderingInOrientation(UIImageOrientation outputOrientation, int renderWidth, int renderHeight) {
	//All transforms have inverted y-axis
	GLKMatrix4 transform;
	const float yInv = -1.0;
	float aspectRatio = (float)renderHeight / renderWidth;
	switch (outputOrientation) {
		default:
		case UIImageOrientationUp:
			transform = cameraMatrixForRect((CGRect){0, 0, renderWidth, renderHeight});
			transform = GLKMatrix4Scale(transform, 1.0f, 1.0f * yInv, 1.0f);
			break;
		case UIImageOrientationUpMirrored:
			transform = cameraMatrixForRect((CGRect){0, 0, renderWidth, renderHeight});
			transform = GLKMatrix4Scale(transform, -1.0f, 1.0f * yInv, 1.0);
			break;
		case UIImageOrientationDown:
			transform = cameraMatrixForRect((CGRect){0, 0, renderWidth, renderHeight});
			transform = GLKMatrix4Scale(transform, -1.0f, -1.0f * yInv, 1.0);
			break;
		case UIImageOrientationDownMirrored:
			transform = cameraMatrixForRect((CGRect){0, 0, renderWidth, renderHeight});
			transform = GLKMatrix4Scale(transform, 1.0f, -1.0f * yInv, 1.0);
			break;
		case UIImageOrientationLeft:
			transform = cameraMatrixForRect((CGRect){0, 0, renderWidth, renderHeight});
			transform = GLKMatrix4RotateZ(transform, -M_PI_2);
			transform = GLKMatrix4Scale(transform, 1.0f, 1.0f * yInv, 1.0);
			transform = GLKMatrix4Scale(transform, aspectRatio, aspectRatio, 1.0);
			break;
		case UIImageOrientationLeftMirrored:
			transform = cameraMatrixForRect((CGRect){0, 0, renderWidth, renderHeight});
			transform = GLKMatrix4RotateZ(transform, -M_PI_2);
			transform = GLKMatrix4Scale(transform, -1.0f, 1.0f * yInv, 1.0);
			transform = GLKMatrix4Scale(transform, aspectRatio, aspectRatio, 1.0);
			break;
		case UIImageOrientationRight:
			transform = cameraMatrixForRect((CGRect){0, 0, renderWidth, renderHeight});
			transform = GLKMatrix4RotateZ(transform, M_PI_2);
			transform = GLKMatrix4Scale(transform, 1.0f, 1.0f * yInv, 1.0f);
			transform = GLKMatrix4Scale(transform, aspectRatio, aspectRatio, 1.0);
			break;
		case UIImageOrientationRightMirrored:
			transform = cameraMatrixForRect((CGRect){0, 0, renderWidth, renderHeight});
			transform = GLKMatrix4RotateZ(transform, M_PI_2);
			transform = GLKMatrix4Scale(transform, -1.0f, 1.0f * yInv, 1.0);
			transform = GLKMatrix4Scale(transform, aspectRatio, aspectRatio, 1.0);
			break;
	}
	return transform;
}