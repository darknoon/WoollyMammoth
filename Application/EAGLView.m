//
//  EAGLView.m
//  NewTemplateTest
//
//  Created by Andrew Pouliot on 10/12/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "EAGLView.h"

#import "WMFramebuffer.h"

void releaseScreenshotData(void *info, const void *data, size_t size) {
	free((void *)data);
};


@interface EAGLView (PrivateMethods)
- (void)createFramebuffer;
- (void)deleteFramebuffer;
@end

@implementation EAGLView

@dynamic context;

// You must implement this method
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (void)sharedInit;
{
	CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
	
	//Support Retina display
	if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
		eaglLayer.contentsScale = [UIScreen mainScreen].scale;
	}
	eaglLayer.opaque = TRUE;
	eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking,
									kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
									nil];
}

//The EAGL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:.
- (id)initWithCoder:(NSCoder*)coder
{
    self = [super initWithCoder:coder];

    [self sharedInit];
	
    return self;
}

- (id)initWithFrame:(CGRect)inFrame {
    self = [super initWithFrame:inFrame];
	if (!self) return nil;
	
	[self sharedInit];
	
    return self;
}

- (void)dealloc
{
    [self deleteFramebuffer];    
    [context release];
    
    [super dealloc];
}

- (WMEAGLContext *)context
{
    return context;
}

- (void)setContext:(WMEAGLContext *)newContext
{
    if (context != newContext)
    {
        [self deleteFramebuffer];
        
        [context release];
        context = [newContext retain];
        
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)deleteFramebuffer
{
    if (context)
    {
        [EAGLContext setCurrentContext:context];
     
		if (context.boundFramebuffer == framebuffer)
		{
			context.boundFramebuffer = nil;
		}
		
		[framebuffer release];
		framebuffer = nil;		
    }
}

- (void)setFramebuffer
{
    if (context)
    {
        [EAGLContext setCurrentContext:context];
        
        if (!framebuffer) {
			framebuffer = [[WMFramebuffer alloc] initWithLayerRenderbufferStorage:(CAEAGLLayer *)self.layer];
		}
        
		context.boundFramebuffer = framebuffer;		
    }
}

- (BOOL)presentFramebuffer
{
    BOOL success = FALSE;
    
    if (context && framebuffer)
    {
        [EAGLContext setCurrentContext:context];
        
		[framebuffer presentRenderbuffer];
    }
    
    return success;
}

- (UIImage *)screenshotImage;
{
	
	[EAGLContext setCurrentContext:context];
	
	GLint framebufferWidth = framebuffer.framebufferWidth;
	GLint framebufferHeight = framebuffer.framebufferHeight;
	
	NSInteger myDataLength = framebufferWidth * framebufferHeight * 4;
	
	// allocate array and read pixels into it.
	GLuint *buffer = (GLuint *) malloc(myDataLength);
	glReadPixels(0, 0, framebufferWidth, framebufferHeight, GL_RGBA, GL_UNSIGNED_BYTE, buffer);

	
	// gl renders "upside down" so swap top to bottom into new array.
	for(int y = 0; y < framebufferHeight / 2; y++) {
		for(int x = 0; x < framebufferWidth; x++) {
			//Swap top and bottom bytes
			GLuint top = buffer[y * framebufferWidth + x];
			GLuint bottom = buffer[(framebufferHeight - 1 - y) * framebufferWidth + x];
			buffer[(framebufferHeight - 1 - y) * framebufferWidth + x] = top;
			buffer[y * framebufferWidth + x] = bottom;
		}
	}
	
	
	
	// prep the ingredients
	const int bitsPerComponent = 8;
	const int bytesPerRow = 4 * framebufferWidth;
	CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
	CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaNoneSkipLast;
	
	//Make CGContext to contain data, and draw into
	CGContextRef cgcontext = CGBitmapContextCreate(buffer,
												   framebufferWidth, framebufferHeight,
												   bitsPerComponent,
												   bytesPerRow,
												   colorSpaceRef, bitmapInfo);
	
	//Draw the image on top
	UIImage *image = [UIImage imageNamed:@"UIOverlay.png"];
	CGContextDrawImage(cgcontext, (CGRect) {.size.width = framebufferWidth, .size.height = framebufferHeight}, [image CGImage]);
	
	// make the cgimage
	CGImageRef imageRef = CGBitmapContextCreateImage(cgcontext);
	CGColorSpaceRelease(colorSpaceRef);
	
	// then make the UIImage from that
	UIImage *myImage = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);
	
	free(buffer);
	
	return myImage;
}

- (void)layoutSubviews
{
    // The framebuffer will be re-created at the beginning of the next setFramebuffer method call.
	[self deleteFramebuffer];
}

@end
