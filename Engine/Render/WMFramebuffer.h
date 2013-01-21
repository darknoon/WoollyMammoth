//
//  WMFramebuffer.h
//  Particulon
//
//  Created by Andrew Pouliot on 4/7/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMRenderCommon.h"

#if TARGET_OS_IPHONE
#import <QuartzCore/CAEAGLLayer.h>
#endif

#import "WMGLStateObject.h"

@class WMTexture2D;

/*!
 @abstract WMFramebuffer encapsulates state relating to an OpenGL framebuffer object. It may be used to render to a texture offscreen or to the contents of a CAEAGLLayer on iOS.
 @discussion
 Create the default WMFramebuffer with -initWithLayerRenderbufferStorage: or allow WMView to create on for you.
 */
@interface WMFramebuffer : WMGLStateObject {
}

#if TARGET_OS_IPHONE
/*!
 @abstract Use this initializer when being used for display to a CAEAGLLayer when no depth buffer is desired.
 
 @param layer The CAEAGLLayer whose renderbuffer rendering should affect.
 */
- (id)initWithLayerRenderbufferStorage:(CAEAGLLayer *)layer;

/*!
 @abstract Create a default framebuffer with a depth buffer attached.
 
 Use this initializer when being used for display to a CAEAGLLayer when no depth buffer is desired.
 
 @param layer The CAEAGLLayer whose renderbuffer rendering should affect.
 @param depthBufferDepth The bit-depth of the depth buffer (if desired). Higher bit depth gives better rendering accuracy and prevents jitter between adjacent surfaces, but may increase rendering times and memory requirements.
 
 GL_DEPTH_COMPONENT16, GL_DEPTH_COMPONENT24_OES, or GL_DEPTH_COMPONENT32_OES are valid inputs to create depth buffer on iOS.
 
 0 indicates that no depth buffer should be created.

 */
- (id)initWithLayerRenderbufferStorage:(CAEAGLLayer *)layer depthBufferDepth:(GLuint)depthBufferDepth;
#elif TARGET_OS_MAC

- (id)initWithGLFramebufferName:(GLuint)framebufferName deleteWhenDone:(BOOL)deleteWhenDone;
- (GLuint)framebufferName;
#endif

+ (NSString *)descriptionOfFramebufferStatus:(GLenum)inStatus;

/*!
 Create a framebuffer for offscreen rendering (render-to-texture) bound to the given texture.
 @discussion
 Init for rendering to the color attachment, mipmap 0 of a WMTexture2D, with an optional depth buffer
 
 @param texture A texture object that will be rendered to
 
 @param depthBufferDepth The bit-depth of the depth buffer (if desired). Higher bit depth gives better rendering accuracy and prevents jitter between adjacent surfaces, but may increase rendering times and memory requirements.
 
 GL_DEPTH_COMPONENT16, GL_DEPTH_COMPONENT24_OES, or GL_DEPTH_COMPONENT32_OES are valid inputs to create depth buffer on iOS.
 
 0 indicates that no depth buffer should be created.
*/
- (id)initWithTexture:(WMTexture2D *)texture depthBufferDepth:(GLuint)depthBufferDepth;

- (void)bind;

//When used for display
- (BOOL)presentRenderbuffer;

//Sets the color attachment mipmap level 0 to be backed by the texture
//This works with inTexture = nil as well, to unset the texture
- (void)setColorAttachmentWithTexture:(WMTexture2D *)inTexture;

@property (nonatomic, readonly) GLint framebufferWidth;
@property (nonatomic, readonly) GLint framebufferHeight;
@property (nonatomic, readonly) BOOL hasDepthbuffer;

@end
