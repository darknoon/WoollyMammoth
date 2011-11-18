//
//  EAGLView.h
//  NewTemplateTest
//
//  Created by Andrew Pouliot on 10/12/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <OpenGLES/EAGL.h>

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import "WMEAGLContext.h"

@class WMFramebuffer;

// This class wraps the CAEAGLLayer from CoreAnimation into a convenient UIView subclass.
// The view content is basically an EAGL surface you render your OpenGL scene into.
// Note that setting the view non-opaque will only work if the EAGL surface has an alpha channel.
@interface EAGLView : UIView

@property (nonatomic, strong) WMEAGLContext *context;

//Render into this framebuffer to output to the screen
//Accessing this property will create a framebuffer if necessary to match the current view bounds
@property (nonatomic, strong, readonly) WMFramebuffer *framebuffer;

@property (nonatomic) GLuint depthBufferDepth;

//You can use this in cases where you want to reclaim the memory being used by the framebuffer, such as going into the background, etc
//The framebuffer will be recreated if necessary
- (void)deleteFramebuffer;

//When you're done rendering, make sure to call -presentRenderbuffer
- (BOOL)presentFramebuffer;

- (UIImage *)screenshotImage;

@end
