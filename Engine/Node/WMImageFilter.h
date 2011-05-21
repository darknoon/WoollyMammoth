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

@interface WMImageFilter : WMPatch {
    WMShader *shader;
	
	WMFramebuffer *framebuffer0;
	WMFramebuffer *framebuffer1;
	
	//For quad
	GLuint vbo;
	GLuint ebo;
	
	WMImagePort *inputImage;
	WMImagePort *outputImage;
}

@end
