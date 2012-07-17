//
//  WMViewController.m
//  NewTemplateTest
//
//  Created by Andrew Pouliot on 10/12/10.
//  Copyright 2010 Darknoon. All rights reserved.
//


#import "WMViewController.h"
#import "EAGLView.h"

#import <QuartzCore/QuartzCore.h>

#import "WMEngine.h"
#import "WMBundleDocument.h"

#import "WMCompositionSerialization.h"

@interface WMViewController ()

@end

@implementation WMViewController {
    CADisplayLink *displayLink;
	
	BOOL openingDocument;
	
	UILabel *fpsLabel;
}

@synthesize document;
@synthesize engine = _engine;
@synthesize animating;
@synthesize eaglView;
@synthesize animationFrameInterval;
@synthesize compositionURL;
@synthesize alwaysPortrait = _alwaysPortrait;

- (void)sharedInit;
{
    animationFrameInterval = 1;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (id)initWithDocument:(WMBundleDocument *)inDocument;
{
	self = [self initWithNibName:nil bundle:nil];
	if (!self) return nil;
	
	document = inDocument;
	
	return self;
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
	if (!self) return nil;
	
	[self sharedInit];
	
    return self;
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
		
		EAGLView *newView = [[EAGLView alloc] initWithFrame:defaultFrame];
		newView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

		self.view = newView;
		self.eaglView = newView;
	}
}

- (void)engineDidLoad;
{
	//TODO: start lazily
	GL_CHECK_ERROR;
	[_engine start];
	GL_CHECK_ERROR;
	
	[eaglView setContext:_engine.renderContext];
}

- (void)setup;
{
	//Recreate engine
	_engine = [[WMEngine alloc] initWithBundle:document];
	_engine.delegate = self;
	
	[self engineDidLoad];
}

- (void)openDocumentAndSetupIfNecessary;
{
	if (!openingDocument) {
		if (document.documentState == UIDocumentStateClosed) {
			[document openWithCompletionHandler:^(BOOL success) {
				if (success) {
					[self setup];
				} else {
					NSLog(@"Error loading composition");
				}
				openingDocument = NO;
			}];
			openingDocument = YES;
		} else if (!_engine) {
			[self setup];
		} 
	}
}

- (void)setDocument:(WMBundleDocument *)inDocument;
{
	if ([document.fileURL isEqual:inDocument.fileURL]) return;

	document = inDocument;
	_engine = nil;
	
	[self openDocumentAndSetupIfNecessary];
}


- (void)viewDidLoad;
{
	[super viewDidLoad];
	
	if ([self.view isKindOfClass:[EAGLView class]]) {
		self.eaglView = (EAGLView *)self.view;
	}
	
	if (!document && self.compositionURL) {
		self.document = [[WMBundleDocument alloc] initWithFileURL:self.compositionURL];
	} else {
		[self openDocumentAndSetupIfNecessary];
	}
	
	fpsLabel = [[UILabel alloc] initWithFrame:CGRectMake(74, 10, 200, 22)];
	fpsLabel.backgroundColor = [UIColor clearColor];
	fpsLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:18.f];
	fpsLabel.textColor = [UIColor whiteColor];
	fpsLabel.shadowColor = [UIColor blackColor];
	fpsLabel.shadowOffset = CGSizeMake(0, 1);
	fpsLabel.alpha = 0.8f;
	fpsLabel.text = @"";
	[self.view addSubview:fpsLabel];
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
    
//	document.preview = [eaglView screenshotImage];
	
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

- (void)startAnimation
{
	[_engine start];
}

- (void)stopAnimation
{
	[_engine stop];
}

- (UIInterfaceOrientation)renderOrientation;
{
	return self.interfaceOrientation;
}

- (BOOL)engineShouldRenderFrame:(WMEngine *)engine;
{
	engine.renderFramebuffer = eaglView.framebuffer;
	engine.frame = eaglView.bounds;
	engine.interfaceOrientation = self.interfaceOrientation;
	
	if (!engine.renderFramebuffer) return NO;
	
	return YES;
}

- (void)engineDidRenderFrame:(WMEngine *)engine;
{
	//TODO: only when changed
	fpsLabel.text = [NSString stringWithFormat:@"%.0lf fps", engine.frameRate];
	fpsLabel.textColor = engine.frameRate > 29.0 ? [UIColor whiteColor] : [UIColor redColor];
}

#pragma mark -

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

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

#pragma mark -
#pragma mark Notifications

- (void)applicationWillResignActive:(UIApplication *)application
{
    [self stopAnimation];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [self startAnimation];
}

- (void)applicationWillEnterForeground:(UIApplication *)application;
{
	[self startAnimation];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [self stopAnimation];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self stopAnimation];
}


@end
