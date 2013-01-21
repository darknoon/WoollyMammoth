//
//  EAGLView.h
//  NewTemplateTest
//
//  Created by Andrew Pouliot on 10/12/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "WMRenderCommon.h"
#import "WMEAGLContext.h"


@class WMFramebuffer;

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#define WMViewSuperclass UIView
#elif TARGET_OS_MAC
#import <AppKit/AppKit.h>
#define WMViewSuperclass NSOpenGLView

#endif

/**
 @abstract A view for rendering OpenGL content.
 @discussion This class wraps the CAEAGLLayer from CoreAnimation into a convenient UIView subclass.
 
 The content of the view's layer is an EAGL surface. Render your OpenGL scene into the framebuffer then call -presentRenderbuffer.
 
 Note that setting the view non-opaque will only work if the EAGL surface has an alpha channel.
*/
@interface WMView : WMViewSuperclass

/** */
@property (nonatomic, strong) WMEAGLContext *context;

/**
 @abstract Get the framebuffer associated with this view
 @discussion Accessing this property will create a framebuffer if necessary to match the current view bounds.
 Render into this framebuffer to output to the screen, then call -presentRenderbuffer.
 */
@property (nonatomic, strong, readonly) WMFramebuffer *framebuffer;

/**
 @abstract Request the bit depth desired for the depth buffer
 @discussion Should be one of the supported OpenGL depth buffer depth constants.

 GL_DEPTH_COMPONENT16, GL_DEPTH_COMPONENT24_OES, or GL_DEPTH_COMPONENT32_OES are valid on iOS.
 
 0 indicates that no depth buffer should be created.

 */
@property (nonatomic) GLuint depthBufferDepth;

/** @abstract Show the framebuffer as the contents of this layer
 @discussion When you're done rendering, you *must* call this method for anything to appear on screen. This method will return when rendering is finished.
 @return YES for success, NO indicates an error occurred
 */
- (BOOL)presentFramebuffer;

#if TARGET_OS_IPHONE
/** @abstract Delete the framebuffer.
 @discussion
 You can use this in cases where you want to reclaim the memory being used by the framebuffer, such as going into the background, etc
 The framebuffer will be recreated if necessary later.
 */
- (void)deleteFramebuffer;

/**
 @abstract Grab a screenshot of the layer's contents
 @discussion uses glReadPixels() to grab the contents of the color buffer.
 @return A UIImage containing the contents of the view
 */
- (UIImage *)screenshotImage;
#endif

@end
