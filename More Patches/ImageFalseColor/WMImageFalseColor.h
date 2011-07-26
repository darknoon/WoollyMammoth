//
//  WMImageFilter.h
//  WMViewer
//
//  Created by Andrew Pouliot on 5/20/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

//For now, hardcoded to a gaussan filter

#import "WMPatch.h"
#import "WMPorts.h"
#import "WMRenderCommon.h"

@class WMShader;
@class WMFramebuffer;
@class WMTexture2D;

@interface WMImageFalseColor : WMPatch {
    WMShader *shader;
	
	WMFramebuffer *fbo;
	WMTexture2D *texMono;
    WMTexture2D *texPal;
	
	//For quad
	GLuint vbo;
	GLuint ebo;
	
	WMImagePort *inputImage;
	WMNumberPort *inputOffset;
	WMImagePort *outputImage;
}

@end
