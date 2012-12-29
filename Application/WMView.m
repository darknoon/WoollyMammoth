//
//  EAGLView.m
//  NewTemplateTest
//
//  Created by Andrew Pouliot on 10/12/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "WMView.h"

#import "WMFramebuffer.h"
#import "WMDisplayLink.h"
#import "WMTexture2D.h"
#import "WMRenderObject+CreateWithGeometry.h"

@interface WMView ()
@end

#if TARGET_OS_IPHONE

@implementation WMView {
@private
    WMEAGLContext *context;
    
	WMFramebuffer *framebuffer;
}

@synthesize depthBufferDepth;

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
	
	depthBufferDepth = GL_DEPTH_COMPONENT16_OES;
	
	eaglLayer.opaque = TRUE;
	eaglLayer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking : @FALSE,
                                     kEAGLDrawablePropertyColorFormat     : kEAGLColorFormatRGBA8};
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
    
}

- (WMFramebuffer *)framebuffer;
{
    if (context)
    {
        [EAGLContext setCurrentContext:context];
        
        if (!framebuffer) {
			framebuffer = [[WMFramebuffer alloc] initWithLayerRenderbufferStorage:(CAEAGLLayer *)self.layer depthBufferDepth:depthBufferDepth];
		}
    }
	return framebuffer;
}

- (WMEAGLContext *)context
{
    return context;
}

- (void)setContext:(WMEAGLContext *)newContext
{
    if (context != newContext) {
		framebuffer = nil;
        
        context = newContext;
        
        [EAGLContext setCurrentContext:context];
    }
}

- (BOOL)presentFramebuffer
{
    BOOL success = FALSE;
    
    if (context && framebuffer) {
        [EAGLContext setCurrentContext:context];
        
		success = [framebuffer presentRenderbuffer];
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
	
	[context renderToFramebuffer:framebuffer block:^{
		glReadPixels(0, 0, framebufferWidth, framebufferHeight, GL_RGBA, GL_UNSIGNED_BYTE, buffer);
	}];
	
	// gl renders "upside down" so swap top to bottom
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
	
	// make the cgimage
	CGImageRef imageRef = CGBitmapContextCreateImage(cgcontext);
	CGColorSpaceRelease(colorSpaceRef);
	
	// then make the UIImage from that
	UIImage *myImage = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);
	
	CGContextRelease(cgcontext);
	free(buffer);
	
	return myImage;
}

- (void)layoutSubviews
{
    // The framebuffer will be re-created at the beginning of the next setFramebuffer method call.
	framebuffer = nil;
}

@end

#elif TARGET_OS_MAC

@implementation WMView {
	WMDisplayLink *_displayLink;
	WMFramebuffer *framebuffer;
	WMRenderObject *_quad;
	WMTexture2D *_framebufferTexture;
}
@synthesize context = _context;

- (void)sharedInit;
{
	self.context = [[WMEAGLContext alloc] initWithOpenGLContext:self.openGLContext];
	
	_displayLink = [[WMDisplayLink alloc] initWithTargetQueue:dispatch_get_main_queue() callback:^(NSTimeInterval t, NSTimeInterval dt) {
		
		[self setNeedsDisplay:YES];
		
	}];
}

- (id)initWithFrame:(NSRect)frame;
{
	self = [super initWithFrame:frame];
	if (!self) return nil;
	
	[self sharedInit];
	
	return self;
}

- (void)awakeFromNib;
{
	[self sharedInit];
	[super awakeFromNib];
}

- (void)drawRect:(NSRect)dirtyRect;
{
	[self drawView];
}

- (void)reshape;
{
	[self setNeedsDisplay:YES];
}

- (void)setFrame:(NSRect)rect;
{
//	if (framebuffer) {
//		framebuffer = nil;
//		_framebufferTexture = nil;
//	}
	[super setFrame:rect];
}

- (void)drawView
{
	WMEAGLContext *context = self.context;
	
	if (!context || context.openGLContext != self.openGLContext) {
		NSLog(@"Can't draw");
		self.context = [[WMEAGLContext alloc] initWithOpenGLContext:self.openGLContext];
		return;
	}
	[WMEAGLContext setCurrentContext:context];
	
	CGLLockContext(context.openGLContext.CGLContextObj);
	[context wm__assumeBoundFramebufferHack];
	
	[context clearToColor:(GLKVector4){0, 0, 0, 0}];
	[context clearDepth];

	if (_framebufferTexture) {
		
		if (!_quad) {
			_quad = [WMRenderObject quadRenderObjectWithFrame:(CGRect){-1,-1,2,2}];
			_quad.shader = [WMShader defaultShader];
			_quad.renderBlendState = DNGLStateBlendEnabled;
			[_quad setValue:[NSValue valueWithGLKVector4:(GLKVector4){1,1,1,1}] forUniformWithName:@"color"];
			[_quad setValue:[NSValue valueWithGLKMatrix4:GLKMatrix4Identity] forUniformWithName:@"wm_T"];
		}
		[_quad setValue:_framebufferTexture forUniformWithName:@"texture"];
		[context renderObject:_quad];
	}

	CGLFlushDrawable([context.openGLContext CGLContextObj]);
	
	CGLUnlockContext(context.openGLContext.CGLContextObj);
}

- (WMFramebuffer *)framebuffer;
{
	if (!framebuffer) {
		[WMEAGLContext setCurrentContext:_context];
		NSRect rect = self.bounds;
		_framebufferTexture = [[WMTexture2D alloc] initEmptyTextureWithPixelFormat:kWMTexture2DPixelFormat_BGRA8888 width:rect.size.width height:rect.size.height];
		framebuffer = [[WMFramebuffer alloc] initWithTexture:_framebufferTexture depthBufferDepth:0];
		
		[_context renderToFramebuffer:framebuffer block:^{
			[_context clearToColor:(GLKVector4){0,0,0,1}];;
			[_context clearDepth];
		}];
		

	}
	return framebuffer;
}

- (void)setContext:(WMEAGLContext *)context;
{
	framebuffer = nil;
	_framebufferTexture = nil;
	_quad = nil;
	_context = context;
	
	self.openGLContext = context.openGLContext;
}

@end

#endif
