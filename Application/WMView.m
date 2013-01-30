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

- (void)deleteFramebuffer;
{
	framebuffer = nil;
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
	BOOL _hasSeenPrepareOpenGL;
}
@synthesize context = _context;

- (void)wmSharedInit;
{
	
}

- (id)initWithCoder:(NSCoder *)aDecoder;
{
	self = [super initWithCoder:aDecoder];
	if (!self) return nil;

	[self wmSharedInit];

	return self;
}

- (id)initWithFrame:(NSRect)frameRect pixelFormat:(NSOpenGLPixelFormat*)format;
{
	self = [super initWithFrame:frameRect pixelFormat:format];
	if (!self) return nil;
		
	[self wmSharedInit];

	return self;
}

- (id)initWithFrame:(NSRect)frame;
{
	self = [super initWithFrame:frame];
	if (!self) return nil;
	
	return self;
}

- (void)awakeFromNib;
{
	[super awakeFromNib];
}

- (void)dealloc
{
	[_context.openGLContext clearDrawable];
	_context = nil;
	[WMEAGLContext setCurrentContext:nil];
}

- (BOOL)presentFramebuffer;
{
	[self setNeedsDisplay:YES];
	return YES;
}

- (void)prepareOpenGL;
{
	[super prepareOpenGL];
	_hasSeenPrepareOpenGL = YES;
}

- (void)reshape;
{
	[super reshape];
}

- (void)setFrame:(NSRect)rect;
{
//	if (framebuffer) {
//		framebuffer = nil;
//		_framebufferTexture = nil;
//	}
	[super setFrame:rect];
}

- (void)drawRect:(NSRect)dirtyRect;
{
//	NSLog(@"in drawRect %@", [self macDebugString]);
	
	WMEAGLContext *context = self.context;
	
	if (!context || context.openGLContext != self.openGLContext) {
		NSLog(@"Can't draw! context does not match %@ %@", context.openGLContext, self.openGLContext);
		return;
	}
	[WMEAGLContext setCurrentContext:context];
	
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

}

- (WMFramebuffer *)framebuffer;
{
	if (!framebuffer) {
		[WMEAGLContext setCurrentContext:self.context];
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

- (void)setOpenGLContext:(NSOpenGLContext *)context;
{
	[super setOpenGLContext:context];
}

- (void)setContext:(WMEAGLContext *)context;
{
	framebuffer = nil;
	_framebufferTexture = nil;
	_quad = nil;
	_context = context;
}

- (WMEAGLContext *)context {
	if (!_context && _hasSeenPrepareOpenGL) {
		_context = [[WMEAGLContext alloc] initWithOpenGLContext:self.openGLContext];
		[_context wm__assumeBoundFramebufferHack];
	}
	return _context;
}

- (NSString *)macDebugString;
{
	GLint boundFramebuffer = -1;
	if ([NSOpenGLContext currentContext]) {
		glGetIntegerv(GL_FRAMEBUFFER_BINDING, &boundFramebuffer);
	}
	
	NSMutableString *ms = [[NSMutableString alloc] init];
	[ms appendFormat:@"current wm context: %@", [WMEAGLContext currentContext]];
	[ms appendString:@"\n\t"];
	[ms appendFormat:@"self.context: %@", self.context];
	[ms appendString:@"\n\t"];
	[ms appendFormat:@"current opengl context: %@", [NSOpenGLContext currentContext]];
	[ms appendString:@"\n\t"];
	[ms appendFormat:@"self.openGLContext: %@", self.openGLContext];
	[ms appendString:@"\n\t"];
	[ms appendFormat:@"current opengl context: %@", [NSOpenGLContext currentContext]];
	[ms appendString:@"\n\t"];
	[ms appendFormat:@"bound framebuffer: %d", boundFramebuffer];
	[ms appendString:@"\n\t"];
	[ms appendFormat:@"wants layer: %d", (int)self.wantsLayer];
	[ms appendString:@"\n\t"];
	[ms appendFormat:@"wants retina surface: %d", (int)self.wantsBestResolutionOpenGLSurface];
	[ms appendString:@"\n\t"];
	[ms appendFormat:@"pixel format: %@", self.pixelFormat];
	[ms appendString:@"\n\t"];
	[ms appendFormat:@"layer: %@", self.layer];
	[ms appendString:@"\n\t"];
	[ms appendFormat:@"wants update layer: %d", (int)self.wantsUpdateLayer];
	[ms appendString:@"\n"];
	[ms appendString:@"\n"];
	
	NSAssert(ms, @"Hmm, string nil");
	ms = [ms copy];
	NSAssert(ms, @"Hmm, string copy nil");
	
	return ms;
}


@end

#endif
