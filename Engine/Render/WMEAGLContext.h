//
//  DNGLState.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 12/8/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMShader.h"

enum {
	DNGLStateBlendEnabled = 1 << 0,
	DNGLStateBlendModeAdd = 1 << 1, //otherwise blend is source-over
} ;
typedef int DNGLStateBlendMask;

enum {
	DNGLStateDepthTestEnabled  = 1 << 0,
	DNGLStateDepthWriteEnabled = 1 << 1,
};
typedef int DNGLStateDepthMask;

@class WMFramebuffer;

@interface WMEAGLContext : EAGLContext {
	//Uses constants from WMShader.h
	int vertexAttributeEnableState;
	DNGLStateBlendMask blendState;
	DNGLStateDepthMask depthState;
	WMFramebuffer *boundFramebuffer;
	
	int maxVertexAttributes;
	
	float modelViewMatrix[16];
}

- (void)setVertexAttributeEnableState:(int)vertexAttributeEnableState;

@property (nonatomic) DNGLStateBlendMask blendState;
@property (nonatomic) DNGLStateDepthMask depthState;
@property (nonatomic, retain) WMFramebuffer *boundFramebuffer;

//This is not GL state in GLES 2.0
//Move to another part of the render engine?
- (void)setModelViewMatrix:(float[16])inModelViewMatrix;
- (void)getModelViewMatrix:(float[16])outModelViewMatrix;

@end
