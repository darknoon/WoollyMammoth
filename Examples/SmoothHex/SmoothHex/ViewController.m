//
//  ViewController.m
//  SmoothHex
//
//  Created by Andrew Pouliot on 1/29/13.
//  Copyright (c) 2013 Darknoon. All rights reserved.
//

#import "ViewController.h"

#import <WMLite/WMLite.h>
#import "DNSmoothHexGeometry.h"
#import "WMSimpleCamera.h"

@interface ViewController ()

@end

@implementation ViewController {
	WMEAGLContext *_context;
	WMView *_glView;
	
	WMRenderObject *_renderObject;
	
	WMSimpleCamera *_camera;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	_context = [[WMEAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
	NSAssert(_context.maxVertexAttributes > 5, @"Must have at least 5 vertex attributes");

	_glView = [[WMView alloc] initWithFrame:self.view.bounds];
	[self.view addSubview:_glView];
	_glView.context = _context;
	_glView.depthBufferDepth = 0;
	
	//Use the camera input to drive updates
	__weak ViewController *weakSelf = self;
	_camera = [[WMSimpleCamera alloc] initWithTargetQueue:dispatch_get_main_queue() context:_context captureBlock:^(WMTexture2D *texture) {
		
		ViewController *self = weakSelf;
		if (!self) return;
		
		[self->_renderObject setValue:texture forUniformWithName:@"texture"];
		
		[self draw];
	}];
}

- (void)viewWillAppear:(BOOL)animated;
{
	DNSmoothHexGeometry *geometry = [[DNSmoothHexGeometry alloc] init];
	geometry.r = 1.0 / 6.0;
	geometry.rect = (CGRect){0,0, 1, self.view.bounds.size.height / self.view.bounds.size.width};
	
	_renderObject = [geometry generate];
	NSError *shaderError = nil;
	_renderObject.shader = [WMShader shaderNamed:@"SmoothHex" error:&shaderError];
	
	WMTexture2D *texture = [[WMTexture2D alloc] initWithImage:[UIImage imageNamed:@"testimage.png"]];
	NSAssert(texture, @"Test texture not found");
	[_renderObject setValue:texture forUniformWithName:@"texture"];
	[_renderObject setValue:@(geometry.r) forUniformWithName:@"r"];
	_renderObject.renderBlendState = WMBlendModeAdd;
	
	if (shaderError) {
		NSLog(@"Shader error: %@", shaderError);
	}
	
	[_camera beginCapture];
	
	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
	
	[super viewWillAppear:animated];
}

- (void)draw;
{
	[_context renderToFramebuffer:_glView.framebuffer block:^{
		[_context clearToColor:[[UIColor colorWithWhite:0.01 alpha:1.0] componentsAsRGBAGLKVector4]];
		[_context renderObject:_renderObject];
	}];
	[_glView presentFramebuffer];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
