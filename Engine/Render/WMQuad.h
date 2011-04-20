//
//  WMQuad.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/21/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMPatch.h"
#import "WMRenderCommon.h"

//Just renders a quad, nothing special :)
@class WMShader;
@class WMImagePort;
@class WMNumberPort;
@class WMColorPort;
@interface WMQuad : WMPatch {
	WMImagePort *inputImage;
	WMNumberPort *inputX;
	WMNumberPort *inputY;
	WMNumberPort *inputScale;
	WMNumberPort *inputRotation;
	WMColorPort *inputColor;
	
	//TODO: add quad features
//	QCOpenGLPort_Image *inputMask;	// 180 = 0xb4
//	QCOpenGLPort_Blending *inputBlending;	// 200 = 0xc8
//	QCBooleanPort *inputPixelAligned;	// 204 = 0xcc

	WMShader *shader;
	GLuint vbo;
	GLuint ebo;
}

@end
