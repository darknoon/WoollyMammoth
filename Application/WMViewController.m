//
//  WMViewController.m
//  NewTemplateTest
//
//  Created by Andrew Pouliot on 10/12/10.
//  Copyright 2010 Darknoon. All rights reserved.
//


#import "WMViewController.h"
#import "WMView.h"

#import <QuartzCore/QuartzCore.h>

#import "WMEngine.h"
#import "WMComposition.h"
#import "WMDisplayLink.h"

#import "WMCompositionSerialization.h"

#if TARGET_OS_IPHONE
@interface WMViewController () <UIActionSheetDelegate>

@end
#endif

@implementation WMViewController {
//    WMDisplayLink *_displayLink;
	
#if TARGET_OS_IPHONE
	UILabel *fpsLabel;
#endif
}

@synthesize document = _document;
@synthesize engine = _engine;
@synthesize animating;
@synthesize eaglView = eaglView;
@synthesize animationFrameInterval;
@synthesize compositionURL;
@synthesize alwaysPortrait = _alwaysPortrait;


- (id)initWithComposition:(WMComposition *)inDocument;
{
	self = [self initWithNibName:nil bundle:nil];
	if (!self) return nil;
	
	_document = inDocument;
	
	return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
	if (!self) return nil;
	
	[self sharedInit];
	
    return self;
}

- (void)setup;
{
	//Recreate engine
	_engine = [[WMEngine alloc] initWithBundle:_document];
	_engine.delegate = self;
	
	[self engineDidLoad];
}

- (void)setDocument:(WMComposition *)inDocument;
{
	if ([_document.fileURL isEqual:inDocument.fileURL]) return;
	
	_document = inDocument;
	_engine = nil;
	
	[self setup];
	[self.engine start];
}

- (void)engineDidLoad;
{
#if TARGET_OS_IPHONE
	[eaglView setContext:_engine.renderContext];
#endif
}

#if TARGET_OS_IPHONE
- (void)sharedInit;
{
    animationFrameInterval = 1;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (!self) return nil;
	
	[self sharedInit];
	
	return self;
}

- (void)loadView;
{
	if (self.nibName) {
		[super loadView];
	}
	if (![self isViewLoaded]) {
		CGRect defaultFrame = [[UIScreen mainScreen] applicationFrame];
		
		WMView *newView = [[WMView alloc] initWithFrame:defaultFrame];
		newView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

		self.view = newView;
		self.eaglView = newView;
	}
}

- (void)viewDidLoad;
{
	[super viewDidLoad];
	
	if ([self.view isKindOfClass:[WMView class]]) {
		self.eaglView = (WMView *)self.view;
	}
	
	if (!_document && self.compositionURL) {
		self.document = [[WMComposition alloc] initWithFileURL:self.compositionURL error:NULL];
	} else {
		[self setup];
	}

#if DEBUG
	fpsLabel = [[UILabel alloc] initWithFrame:CGRectMake(74, 10, 200, 22)];
	fpsLabel.backgroundColor = [UIColor clearColor];
	fpsLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:18.f];
	fpsLabel.textColor = [UIColor whiteColor];
	fpsLabel.shadowColor = [UIColor blackColor];
	fpsLabel.shadowOffset = CGSizeMake(0, 1);
	fpsLabel.alpha = 0.8f;
	fpsLabel.text = @"";
	[self.view addSubview:fpsLabel];
#endif
}

- (void)viewWillAppear:(BOOL)animated
{
    [self startAnimation];
	
	//Disable screen dim / turn off because we don't use touch input
	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self stopAnimation];
    
	[[UIApplication sharedApplication] setIdleTimerDisabled:NO];
	
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
	fpsLabel = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation; // Override to allow rotation. Default returns YES only for UIDeviceOrientationPortrait
{
	return !_alwaysPortrait || UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (UIImage *)screenshotImage;
{
	return [eaglView screenshotImage];
}


#pragma mark -
#pragma mark Actions

- (void)toggleNavigationBar;
{
	[self.navigationController setNavigationBarHidden:!self.navigationController.navigationBarHidden animated:NO];
}

#pragma mark -
#pragma mark Notifications

- (void)applicationWillResignActive:(NSNotification *)note;
{
    [self stopAnimation];
}

- (void)applicationDidBecomeActive:(NSNotification *)note;
{
    [self startAnimation];
}

- (void)applicationWillEnterForeground:(NSNotification *)note;
{
	[self startAnimation];
}

- (void)applicationDidEnterBackground:(NSNotification *)note;
{
    [self stopAnimation];
}

- (void)applicationWillTerminate:(NSNotification *)note;
{
    [self stopAnimation];
}


- (UIInterfaceOrientation)renderOrientation;
{
	return self.interfaceOrientation;
}

- (BOOL)engineShouldRenderFrame:(WMEngine *)engine;
{
	engine.renderFramebuffer = eaglView.framebuffer;
	engine.frame = eaglView.bounds;
	engine.interfaceOrientation = self.renderOrientation;
	
	if (!engine.renderFramebuffer) return NO;
	
	return YES;
}

- (void)engineDidRenderFrame:(WMEngine *)engine;
{
	//TODO: only when changed
	fpsLabel.text = [NSString stringWithFormat:@"%.0lf fps", engine.frameRate];
	fpsLabel.textColor = engine.frameRate > 29.0 ? [UIColor whiteColor] : [UIColor redColor];
}


#elif TARGET_OS_MAC

- (void)setView:(NSView *)view;
{
	[super setView:view];
	eaglView = (WMView *)view;
	WMEAGLContext *context = ((WMView *)view).context;
	self.engine.renderContext = context;
	
#warning FIND ANOTHER WAY
	int64_t delayInSeconds = 2.0;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		WMEAGLContext *context = ((WMView *)view).context;
		[self setup];
		self.engine.renderContext = context;
		[self.engine start];
	});	
}

- (void)sharedInit;
{
    animationFrameInterval = 1;

}

- (BOOL)engineShouldRenderFrame:(WMEngine *)engine;
{
	engine.renderFramebuffer = eaglView.framebuffer;
	engine.frame = eaglView.bounds;
	engine.interfaceOrientation = self.renderOrientation;
	
	if (!engine.renderFramebuffer) return NO;
	
	return YES;
}



- (void)engineDidRenderFrame:(WMEngine *)engine;
{
}

#endif


- (void)startAnimation
{
	[_engine start];
}

- (void)stopAnimation
{
	[_engine stop];
}


@end
