//
//  WMFramebuffer.h
//  Particulon
//
//  Created by Andrew Pouliot on 4/7/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMRenderCommon.h"

#import <QuartzCore/CAEAGLLayer.h>

@class WMTexture2D;

@interface WMFramebuffer : NSObject {
	GLint framebufferWidth;
    GLint framebufferHeight;
	
	//If rendering to a texture
	WMTexture2D *texture;
	
	GLuint colorRenderbuffer;
	GLuint depthRenderbuffer;
	GLuint framebufferObject;
}

//Use this initializer when being used for display
- (id)initWithLayerRenderbufferStorage:(CAEAGLLayer *)inLayer;

//Init for rendering to the color attachment, mipmap 0 of a WMTexture2D, with an optional depth buffer
//Pass in depthBufferDepth = GL_DEPTH_COMPONENT16 or GL_DEPTH_COMPONENT32_OES for a depth buffer, 0 otherwise
- (id)initWithTexture:(WMTexture2D *)inTexture depthBufferDepth:(GLuint)inDepthBufferDepth;

- (void)bind;

//When used for display
- (BOOL)presentRenderbuffer;

@property (nonatomic, readonly) WMTexture2D *texture;

@property (nonatomic, readonly) GLint framebufferWidth;
@property (nonatomic, readonly) GLint framebufferHeight;
@property (nonatomic, readonly) BOOL hasDepthbuffer;

@end
