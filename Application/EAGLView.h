//
//  EAGLView.h
//  NewTemplateTest
//
//  Created by Andrew Pouliot on 10/12/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <OpenGLES/EAGL.h>

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import "WMEAGLContext.h"

@class WMFramebuffer;

// This class wraps the CAEAGLLayer from CoreAnimation into a convenient UIView subclass.
// The view content is basically an EAGL surface you render your OpenGL scene into.
// Note that setting the view non-opaque will only work if the EAGL surface has an alpha channel.
@interface EAGLView : UIView
{
@private
    WMEAGLContext *context;
    
	WMFramebuffer *framebuffer;
	
    // The pixel dimensions of the CAEAGLLayer.
	
	dispatch_queue_t gl_queue;
}

@property (nonatomic) dispatch_queue_t gl_queue;

@property (nonatomic, retain) WMEAGLContext *context;

- (void)setFramebuffer;
- (BOOL)presentFramebuffer;

- (UIImage *)screenshotImage;

@end
