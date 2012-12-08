//
//  BasicGLView.m
//  BasicGL
//
//  Created by Andrew Pouliot on 12/7/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import "BasicGLView.h"

#import <WMLite/WMLite.h>

@implementation BasicGLView {
	WMDisplayLink *_displayLink;
	WMRenderObject *_quad;
	
	WMEAGLContext *_context;
	
	double _t;
}

- (void)awakeFromNib;
{
	[self setup];
	[super awakeFromNib];
}

- (void)setup;
{
	_context = [[WMEAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
	self.openGLContext = _context;
	
	//Draw a circle into an OpenGL texture
	CGSize textureSize = (CGSize){64,64};
	WMTexture2D *texture = [[WMTexture2D alloc] initWithBitmapSize:textureSize block:^(CGContextRef ctx) {
		CGContextSetFillColorWithColor(ctx, CGColorCreateGenericGray(1.0f, 1.0f));
		CGContextFillEllipseInRect(ctx, CGRectInset((CGRect){{0.f, 0.f}, textureSize}, 1.f, 1.f) );
	}];
	
	//Creating the WMRenderObject and keeping it around is more efficient than recreating each frame
	_quad = [WMRenderObject quadRenderObjectWithFrame:(CGRect){{0, 0}, textureSize}];
	//Use the default shader (render a quad with a texture multiplied by a color)
	_quad.shader = [WMShader defaultShader];
	//Use "normal" blending (source-over with premultiplied alpha)
	_quad.renderBlendState = DNGLStateBlendEnabled;
	//Attach the texture as the input for the "texture" uniform
	[_quad setValue:texture forUniformWithName:@"texture"];
	
	//Make a display link to drive updates
	__weak BasicGLView *weakSelf = self;
	_displayLink = [[WMDisplayLink alloc] initWithTargetQueue:dispatch_get_main_queue() callback:^(NSTimeInterval t, NSTimeInterval dt) {
		BasicGLView *self = weakSelf;
		if (!self) return;
		
		self->_t = t;
		[self drawAtTime:t];
	}];
	
	self.wantsBestResolutionOpenGLSurface = YES;
	
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) return nil;
	
	[self setup];
	
    return self;
}

static GLKVector4 GLKVector4_HSV_to_RGB(GLKVector4 HSV )
{
	float hue_6 = HSV.v[0] * 6,
	      saturation = HSV.v[1],
	      value = HSV.v[2];

	if (hue_6 == 0.0f) hue_6 = 0.01f;
	int i = floorf(hue_6);
	
	float f = hue_6 - i;
	if(!(i & 1)) f = 1 - f; // if i is even
	float m = value * (1 - saturation);
	float n = value * (1 - saturation * f);
	switch (i) {
		case 6:
		case 0: return GLKVector4Make(value, n, m, HSV.a);
		case 1: return GLKVector4Make(n, value, m, HSV.a);
		case 2: return GLKVector4Make(m, value, n, HSV.a);
		case 3: return GLKVector4Make(m, n, value, HSV.a);
		case 4: return GLKVector4Make(n, m, value, HSV.a);
		case 5: return GLKVector4Make(value, m, n, HSV.a);
		default: return GLKVector4Make(0, 0, 0, HSV.a);
	}
}


- (void)drawAtTime:(double)t;
{
	CGLLockContext(self.openGLContext.CGLContextObj);
	
	WMEAGLContext *context = (WMEAGLContext *)self.openGLContext;
	[WMEAGLContext setCurrentContext:context];
	
	NSSize contentSize = self.bounds.size;
	
//	glViewport(0, 0, contentSize.width, contentSize.height);

	CGRect bounds = self.bounds;
	
	//TODO: make it more elegant to create an NSValue with a GLKVector4 from a UIColor
	GLKVector4 colorVector = GLKVector4_HSV_to_RGB(GLKVector4Make(fmod(t / 1.4, 1.0), 1.0f, 0.8f, 0.5 + 0.2 * cos(t / 3.0)));
	[_quad setValue:[NSValue valueWithGLKVector4:colorVector] forUniformWithName:@"color"];
	
	CGFloat distance = 0.6 * bounds.size.width;
	double period = 20.0;
	CGPoint position = (CGPoint){distance * sin(11.0 * t * 2.0 * M_PI / period), distance * cos(7.0 * t * 2.0 * M_PI / period)};
	
	//Create a matrix to map UIKit coordinates to GL coordinates
	GLKMatrix4 viewTransform = GLKMatrix4MakeScale(1.0f / bounds.size.width, 1.0f / bounds.size.height, 0.0f);
	[_quad setValue:[NSValue valueWithBytes:&viewTransform objCType:@encode(GLKMatrix4)] forUniformWithName:@"wm_T"];
	[_quad postmultiplyTransform:GLKMatrix4MakeTranslation(position.x, position.y, -1.0f)];
	
	[_context clearToColor:GLKVector4Make(0.2f, 0.2f, 0.2f, 1.0f)];
	[_context renderObject:_quad];

	
	CGLFlushDrawable([[self openGLContext] CGLContextObj]);
	
	CGLUnlockContext(self.openGLContext.CGLContextObj);
}

- (void)drawRect:(NSRect)dirtyRect;
{
	[self drawAtTime:_t];
}


@end
