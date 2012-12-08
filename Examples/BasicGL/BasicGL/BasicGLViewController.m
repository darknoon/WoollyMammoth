//
//  BasicGLViewController.m
//  BasicGL
//
//  Created by Andrew Pouliot on 12/7/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import "BasicGLViewController.h"

#import <WMLite/WMLite.h>

@interface BasicGLViewController ()

@end

@implementation BasicGLViewController {
	WMDisplayLink *_displayLink;
	WMView *_glView;
	WMRenderObject *_quad;
	
	WMEAGLContext *_context;
}

- (void)viewDidLoad
{
	//Set up our context and view to render into
	_context = [[WMEAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
	_glView = [[WMView alloc] initWithFrame:self.view.bounds];
	_glView.context = _context;
	_glView.depthBufferDepth = 0;
	
	//Draw a circle into an OpenGL texture
	CGSize textureSize = (CGSize){64,64};
	WMTexture2D *texture = [[WMTexture2D alloc] initWithBitmapSize:textureSize block:^(CGContextRef ctx) {
		CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
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
	__weak BasicGLViewController *weakSelf = self;
	_displayLink = [[WMDisplayLink alloc] initWithTargetQueue:dispatch_get_main_queue() callback:^(NSTimeInterval t, NSTimeInterval dt) {
		BasicGLViewController *self = weakSelf;
		if (!self) return;
		
		[self drawAtTime:t];
		
	}];
	
	[self.view addSubview:_glView];
    [super viewDidLoad];
}

- (void)drawAtTime:(double)t;
{
	[WMEAGLContext setCurrentContext:_context];
	
	CGRect bounds = _glView.bounds;
	
	//TODO: make it more elegant to create an NSValue with a GLKVector4 from a UIColor
	UIColor *cc = [UIColor colorWithHue:fmod(t / 1.4, 1.0) saturation:1.0f brightness:0.8f alpha:0.5 + 0.2 * cos(t / 3.0)];
	GLKVector4 colorVector;
	memcpy(&colorVector.v, CGColorGetComponents(cc.CGColor), sizeof(colorVector.v));
	[_quad setValue:[NSValue valueWithGLKVector4:colorVector] forUniformWithName:@"color"];

	CGFloat distance = 0.6 * bounds.size.width;
	double period = 20.0;
	CGPoint position = (CGPoint){distance * sin(11.0 * t * 2.0 * M_PI / period), distance * cos(7.0 * t * 2.0 * M_PI / period)};

	//Create a matrix to map UIKit coordinates to GL coordinates
	GLKMatrix4 viewTransform = GLKMatrix4MakeScale(1.0f / bounds.size.width, 1.0f / bounds.size.height, 0.0f);
	[_quad setValue:[NSValue valueWithBytes:&viewTransform objCType:@encode(GLKMatrix4)] forUniformWithName:@"wm_T"];
	[_quad postmultiplyTransform:GLKMatrix4MakeTranslation(position.x, position.y, -1.0f)];
	
	[_context renderToFramebuffer:_glView.framebuffer block:^{
		[_context clearToColor:GLKVector4Make(0.2f, 0.2f, 0.2f, 1.0f)];
		[_context renderObject:_quad];
	}];
	
	[_glView.framebuffer presentRenderbuffer];
	
}


@end
