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

@implementation WMViewController {
    CADisplayLink *displayLink;
	
	BOOL openingDocument;
	
	UILabel *fpsLabel;
	
	//Used to calculate actual FPS
	NSTimeInterval lastFrameEndTime;
	double lastFPSUpdate;
	NSUInteger framesSinceLastFPSUpdate;
}

@synthesize document;
@synthesize engine;
@synthesize animating;
@synthesize eaglView;
@synthesize animationFrameInterval;
@synthesize compositionURL;

- (void)sharedInit;
{
    animationFrameInterval = 1;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
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
	[engine start];
	GL_CHECK_ERROR;
	
	[eaglView setContext:engine.renderContext];
}

- (void)setup;
{
	//Recreate engine
	engine = [[WMEngine alloc] initWithBundle:document];
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
		} else if (!engine) {
			[self setup];
		} 
	}
}

- (void)setDocument:(WMBundleDocument *)inDocument;
{
	if ([document.fileURL isEqual:inDocument.fileURL]) return;

	document = inDocument;
	engine = nil;
	
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
    
	document.preview = [eaglView screenshotImage];
	
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
		displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(drawFrame)];
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

- (UIInterfaceOrientation)renderOrientation;
{
	return self.interfaceOrientation;
}

- (void)drawFrame
{
	[engine.renderContext renderToFramebuffer:eaglView.framebuffer block:^{
		NSTimeInterval frameStartTime = CFAbsoluteTimeGetCurrent();
		
		[engine drawFrameInRect:eaglView.bounds interfaceOrientation:self.interfaceOrientation];
		
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

	}];	

	[eaglView presentFramebuffer];
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

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self stopAnimation];
}


@end
