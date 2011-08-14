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
#import "WMDebugViewController.h"

#import "DNQCComposition.h"

@interface WMViewController ()

@property (nonatomic, copy) NSURL *compositionURL;

@end

@implementation WMViewController {
    CADisplayLink *displayLink;
	
	UILabel *fpsLabel;
	
	//Used to calculate actual FPS
	NSTimeInterval lastFrameEndTime;
	double lastFPSUpdate;
	NSUInteger framesSinceLastFPSUpdate;
}


@synthesize engine;
@synthesize animating;
@synthesize debugViewController;
@synthesize animationFrameInterval;
@synthesize compositionURL;

- (void)sharedInit;
{
    animationFrameInterval = 1;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
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

- (id)initWithRootPatch:(WMPatch *)inPatch;
{
	self = [super initWithNibName:nil bundle:nil];
	if (!self) return nil;
		
	self.compositionURL = nil;
	
	GL_CHECK_ERROR;
	engine = [[WMEngine alloc] initWithRootObject:inPatch userData:nil];
	
	//TODO: start lazily
	GL_CHECK_ERROR;
	[engine start];
	GL_CHECK_ERROR;
	
	[(EAGLView *)self.view setContext:engine.renderContext];
	//This will create a framebuffer and set it on the context
    [(EAGLView *)self.view setFramebuffer];
	
	
	return self;
}

- (void)reloadEngine;
{
	[self reloadEngineFromURL:self.compositionURL];
}

- (void)reloadEngineFromURL:(NSURL *)inURL;
{
	if (engine) {
		[engine release];
		engine = nil;
	}
	
	self.compositionURL = inURL;
	
	NSString *filePath = [inURL path];
	NSError *error = nil;
	DNQCComposition *composition = [[DNQCComposition alloc] initWithContentsOfFile:filePath  error:&error];
	
	GL_CHECK_ERROR;
	engine = [[WMEngine alloc] initWithComposition:composition];
	
	//TODO: start lazily
	GL_CHECK_ERROR;
	[engine start];
	GL_CHECK_ERROR;
	
	[(EAGLView *)self.view setContext:engine.renderContext];
	//This will create a framebuffer and set it on the context
    [(EAGLView *)self.view setFramebuffer];
	
}

- (void)loadView;
{
	CGRect defaultFrame = [[UIScreen mainScreen] applicationFrame];
	EAGLView *view = [[[EAGLView alloc] initWithFrame:defaultFrame] autorelease];
	view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	self.view = view;
}

- (void)viewDidLoad;
{
	[super viewDidLoad];
	fpsLabel = [[UILabel alloc] initWithFrame:CGRectMake(74, 10, 200, 22)];
	fpsLabel.backgroundColor = [UIColor clearColor];
	fpsLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:18.f];
	fpsLabel.textColor = [UIColor whiteColor];
	fpsLabel.shadowColor = [UIColor blackColor];
	fpsLabel.shadowOffset = CGSizeMake(0, 1);
	fpsLabel.alpha = 0.8f;
	fpsLabel.text = @"";
	[self.view addSubview:fpsLabel];
	
	UITapGestureRecognizer *tapRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleNavigationBar)] autorelease];
	[self.view addGestureRecognizer:tapRecognizer];
}

- (void)dealloc
{    
    [engine release];
	[debugViewController release];
    [super dealloc];
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
	[fpsLabel release];
	fpsLabel = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation; // Override to allow rotation. Default returns YES only for UIDeviceOrientationPortrait
{
	return YES;
}

- (NSInteger)animationFrameInterval
{
    return animationFrameInterval;
}

- (void)setAnimationFrameInterval:(NSInteger)frameInterval
{
    /*
	 Frame interval defines how many display frames must pass between each time the display link fires.
	 The display link will only fire 30 times a second when the frame internal is two on a display that refreshes 60 times a second. The default frame interval setting of one will fire 60 times a second when the display refreshes at 60 times a second. A frame interval setting of less than one results in undefined behavior.
	 */
    if (frameInterval >= 1)
    {
        animationFrameInterval = frameInterval;
        
        if (animating)
        {
            [self stopAnimation];
            [self startAnimation];
        }
    }
}

- (void)startAnimation
{
    if (!animating)
    {
		displayLink = [NSClassFromString(@"CADisplayLink") displayLinkWithTarget:self selector:@selector(drawFrame)];
		[displayLink setFrameInterval:animationFrameInterval];
		
		// The run loop will retain the display link on add.
		[displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

        animating = TRUE;
		lastFrameEndTime = CFAbsoluteTimeGetCurrent();
    }
}

- (void)stopAnimation
{
    if (animating)
    {
		[displayLink invalidate];
		displayLink = nil;
        
        animating = FALSE;
    }
}

- (void)drawFrame
{
    [(EAGLView *)self.view setFramebuffer];
 
	
	
	NSTimeInterval frameStartTime = CFAbsoluteTimeGetCurrent();
	
	[engine drawFrameInRect:self.view.bounds interfaceOrientation:self.interfaceOrientation];
	
	NSTimeInterval frameEndTime = CFAbsoluteTimeGetCurrent();
	
	NSTimeInterval timeToDrawFrame = frameEndTime - frameStartTime;
	
	framesSinceLastFPSUpdate++;
	if (frameEndTime - lastFPSUpdate > 1.0) {
		float fps = framesSinceLastFPSUpdate;
		framesSinceLastFPSUpdate = 0;
		
//TODO: if not release...
		fpsLabel.text = [NSString stringWithFormat:@"%.0lf fps (%.0lf ms)", fps, timeToDrawFrame * 1000.0];		

		lastFPSUpdate = frameEndTime;
	}
	
	
	lastFrameEndTime = frameEndTime;

    [(EAGLView *)self.view presentFramebuffer];
	
	glFlush();
}

#pragma mark -

- (UIImage *)screenshotImage;
{
	return [(EAGLView *)self.view screenshotImage];
}


#pragma mark -
#pragma mark Actions

- (void)toggleNavigationBar;
{
	[self.navigationController setNavigationBarHidden:!self.navigationController.navigationBarHidden animated:NO];
}

- (IBAction)showDebug:(id)sender;
{
	[self.view addSubview:debugViewController.view];
	debugViewController.view.frame = self.view.bounds;
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

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self stopAnimation];
}


@end
