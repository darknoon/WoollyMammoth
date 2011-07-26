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

@interface WMImageFilter : WMPatch {
    WMShader *shader;
	
	WMFramebuffer *fbo;
	WMTexture2D *texture0;
	WMTexture2D *texture1;
	
	//For quad
	GLuint vbo;
	GLuint ebo;
	
	WMNumberPort *inputRadius;
	WMImagePort *inputImage;
	WMImagePort *outputImage;
}

@end
