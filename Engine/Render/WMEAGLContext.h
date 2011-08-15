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

@interface WMEAGLContext : EAGLContext

//This also controls glViewport at the moment. Perhaps this will change in the future.
@property (nonatomic, retain) WMFramebuffer *boundFramebuffer;

- (void)renderObject:(WMRenderObject *)inObject;

//Clears the color buffer to the given color
- (void)clearToColor:(GLKVector4)inColor;

//Clears the depth buffer to the default depth (+inf?)
- (void)clearDepth;

//This is not GL state in GLES 2.0
//TODO: Move to another part of the render engine.
@property (nonatomic) GLKMatrix4 modelViewMatrix;

@property (nonatomic, readonly) int maxTextureSize;
@property (nonatomic, readonly) int maxVertexAttributes;
@property (nonatomic, readonly) int maxTextureUnits;

@end
