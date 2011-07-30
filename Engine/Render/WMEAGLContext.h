//
//  Created by Andrew Pouliot on 12/8/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMShader.h"
#import <GLKit/GLKit.h>

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
@class WMRenderObject;

@interface WMEAGLContext : EAGLContext {
	int vertexAttributeEnableState;
	DNGLStateBlendMask blendState;
	DNGLStateDepthMask depthState;
	WMFramebuffer *boundFramebuffer;
	CGRect viewport;
	
	int maxVertexAttributes;
	int maxTextureUnits;
}

- (void)setVertexAttributeEnableState:(int)vertexAttributeEnableState;

@property (nonatomic) DNGLStateBlendMask blendState;
@property (nonatomic) DNGLStateDepthMask depthState;

//This also controls glViewport at the moment. Perhaps this will change in the future.
@property (nonatomic, retain) WMFramebuffer *boundFramebuffer;

- (void)renderObject:(WMRenderObject *)inObject;

//This is not GL state in GLES 2.0
//TODO: Move to another part of the render engine.
@property (nonatomic) GLKMatrix4 modelViewMatrix;

@end
