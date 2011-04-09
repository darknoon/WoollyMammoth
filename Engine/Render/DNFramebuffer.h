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

@interface DNFramebuffer : NSObject {
	GLint framebufferWidth;
    GLint framebufferHeight;
	
	GLuint colorRenderbuffer;
	GLuint depthRenderbuffer;
	GLuint framebufferObject;
}

- (id)initWithLayerRenderbufferStorage:(CAEAGLLayer *)inLayer;

//Init for rendering to texture
- (id)init;

- (void)bind;

//When used for display
- (BOOL)presentRenderbuffer;

@property (nonatomic, readonly) GLint framebufferWidth;
@property (nonatomic, readonly) GLint framebufferHeight;

@end
