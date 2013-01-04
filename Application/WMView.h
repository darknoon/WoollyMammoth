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

// This class wraps the CAEAGLLayer from CoreAnimation into a convenient UIView subclass.
// The view content is basically an EAGL surface you render your OpenGL scene into.
// Note that setting the view non-opaque will only work if the EAGL surface has an alpha channel.
@interface WMView : WMViewSuperclass

@property (nonatomic, strong) WMEAGLContext *context;

//Render into this framebuffer to output to the screen
//Accessing this property will create a framebuffer if necessary to match the current view bounds
@property (nonatomic, strong, readonly) WMFramebuffer *framebuffer;

@property (nonatomic) GLuint depthBufferDepth;

//When you're done rendering, make sure to call -presentRenderbuffer
- (BOOL)presentFramebuffer;

#if TARGET_OS_IPHONE
//You can use this in cases where you want to reclaim the memory being used by the framebuffer, such as going into the background, etc
//The framebuffer will be recreated if necessary
- (void)deleteFramebuffer;

- (UIImage *)screenshotImage;
#endif

@end
