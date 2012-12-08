//
//  DNPCViewController.m
//  ParticleCascade
//
//  Created by Andrew Pouliot on 9/19/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import "DNPCViewController.h"

#import "DNPCParticleCascader.h"
#import "DNPCPostProcess.h"

@interface DNPCViewController ()

@property (nonatomic) BOOL showingFPSMeter;

@end

@implementation DNPCViewController {
	WMView *_glView;
	WMEAGLContext *_context;
	DNPCParticleCascader *_particles;
	
	WMTexture2D *_rttTexture;
	WMFramebuffer *_rttFramebuffer;
	
	DNPCPostProcess *_post;
	
	UILabel *_fpsMeter;
	
	NSTimeInterval _startTime;
	WMDisplayLink *_displayLink;
	WMFrameCounter *_frameCounter;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

	_context = [[WMEAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    _shouldPostProcess = YES;
	
	return self;
}

- (void)loadView
{
	[EAGLContext setCurrentContext:_context];
	UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	
	_glView = [[WMView alloc] initWithFrame:view.bounds];
	_glView.backgroundColor = [UIColor blackColor];
	[view addSubview:_glView];
	
	_fpsMeter = [[UILabel alloc] initWithFrame:(CGRect){20,0, 100, 40}];
	_fpsMeter.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18.f];
	_fpsMeter.backgroundColor = [UIColor clearColor];
	_fpsMeter.textColor = [UIColor colorWithWhite:1.0 alpha:0.2];
	[view addSubview:_fpsMeter];
	
	_glView.depthBufferDepth = 0;
	_glView.context = _context;
	
	self.view = view;

	_post = [[DNPCPostProcess alloc] init];
	
	_particles = [[DNPCParticleCascader alloc] initWithParticleCount:8000];
	_particles.inputPoint = (GLKVector2){0.5, 0.5};
	
	CGSize size = view.bounds.size;
	CGFloat devicePixelRatio = [UIScreen mainScreen].scale;
	_rttTexture = [[WMTexture2D alloc] initWithData:NULL pixelFormat:kWMTexture2DPixelFormat_R8 pixelsWide:size.width * devicePixelRatio pixelsHigh:size.height * devicePixelRatio contentSize:size];
	_rttFramebuffer = [[WMFramebuffer alloc] initWithTexture:_rttTexture depthBufferDepth:0];
	
	_startTime = CACurrentMediaTime();
	
	_frameCounter = [[WMFrameCounter alloc] init];

	_displayLink = [[WMDisplayLink alloc] initWithTargetQueue:dispatch_get_main_queue() callback:^(NSTimeInterval t, NSTimeInterval dt) {
		
		[EAGLContext setCurrentContext:_context];
		double before = CACurrentMediaTime();
		[self drawGLContent];
		double after = CACurrentMediaTime();
		[_frameCounter recordFrameWithTime:after duration:before - after];
		
	}];

	[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(_updateFPS) userInfo:nil repeats:YES];
}

- (void)_updateFPS;
{
	_fpsMeter.text = [NSString stringWithFormat:@"%.0lf", _frameCounter.fps];
}

- (void)drawGLContent;
{
	
	[_glView.framebuffer presentRenderbuffer];

	if (_shouldPostProcess) {
		[_context renderToFramebuffer:_rttFramebuffer block:^{
			[_context clearToColor:(GLKVector4){0, 0, 0, 1}];
			[_particles render];
		}];
		[_post processTexture:_rttTexture renderToFramebuffer:_glView.framebuffer];
	} else {
		[_context renderToFramebuffer:_glView.framebuffer block:^{
			[_context clearToColor:(GLKVector4){0, 0, 0, 1}];
			[_particles render];
		}];
	}

	[_particles updateWithTime:CACurrentMediaTime() - _startTime dt:1.0 / 60.0];
}

- (GLKVector2)convertPointToGL:(CGPoint)p;
{
	CGSize size = _glView.bounds.size;
	return (GLKVector2){2.0 * p.x / size.width - 1.0, 1.0 - 2.0 * p.y / size.height };
}

- (CGPoint)convertPointFromGL:(GLKVector2)p;
{
	CGSize size = _glView.bounds.size;
	return (CGPoint){0.5 * p.x * size.width, 0.5 * (1.0 - p.y) * size.height };
}

- (void)setShowingFPSMeter:(BOOL)showingFPSMeter;
{
	
}


//This touch handling is shit :P
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
{
	_particles.inputPoint = [self convertPointToGL:[[touches anyObject] locationInView:_glView]];
	_particles.touchIsDown = YES;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
{
	_particles.inputPoint = [self convertPointToGL:[[touches anyObject] locationInView:_glView]];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
{
	int touchCount = [event touchesForView:_glView].count;
	_particles.inputPoint = [self convertPointToGL:[[touches anyObject] locationInView:_glView]];
	_particles.touchIsDown = touchCount > 1;
}

@end
