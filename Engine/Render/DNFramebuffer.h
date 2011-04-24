//
//  DNFramebuffer.h
//  Particulon
//
//  Created by Andrew Pouliot on 4/7/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMRenderCommon.h"

#import <QuartzCore/CAEAGLLayer.h>

@class Texture2D;

@interface DNFramebuffer : NSObject {
	GLint framebufferWidth;
    GLint framebufferHeight;
	
	GLuint textureName;
	
	GLuint colorRenderbuffer;
	GLuint depthRenderbuffer;
	GLuint framebufferObject;
}

//Use this initializer when being used for display
- (id)initWithLayerRenderbufferStorage:(CAEAGLLayer *)inLayer;

//Init for rendering to the color attachment, mipmap 0 of a Texture2D, with an optional depth buffer
//Pass in depthBufferDepth = GL_DEPTH_COMPONENT16 or GL_DEPTH_COMPONENT32_OES for a depth buffer, 0 otherwise
- (id)initWithTexture:(Texture2D *)inTexture depthBufferDepth:(GLuint)inDepthBufferDepth;

- (void)bind;

//When used for display
- (BOOL)presentRenderbuffer;

@property (nonatomic, readonly) GLint framebufferWidth;
@property (nonatomic, readonly) GLint framebufferHeight;
@property (nonatomic, readonly) BOOL hasDepthbuffer;

@end
