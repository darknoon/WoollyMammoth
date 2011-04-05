//
//  WMViewController.h
//  NewTemplateTest
//
//  Created by Andrew Pouliot on 10/12/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@class WMEngine;
@class WMDebugViewController;

@interface WMViewController : UIViewController <UIActionSheetDelegate>
{
	WMEngine *engine;
	    
    BOOL animating;
    BOOL displayLinkSupported;
    NSInteger animationFrameInterval;
    /*
	 Use of the CADisplayLink class is the preferred method for controlling your animation timing.
	 CADisplayLink will link to the main display and fire every vsync when added to a given run-loop.
	 The NSTimer object is used only as fallback when running on a pre-3.1 device where CADisplayLink isn't available.
	 */
    id displayLink;
    NSTimer *animationTimer;
	
	UILabel *fpsLabel;
	IBOutlet WMDebugViewController *debugViewController;
		
	//Used to calculate actual FPS
	NSTimeInterval lastFrameEndTime;
	double lastFPSUpdate;
	NSUInteger framesSinceLastFPSUpdate;
}

@property (readonly, retain) WMEngine *engine;
@property (readonly, nonatomic, getter=isAnimating) BOOL animating;
@property (nonatomic) NSInteger animationFrameInterval;
@property (nonatomic, retain) IBOutlet WMDebugViewController *debugViewController;

- (UIImage *)screenshotImage;

- (IBAction)showDebug:(id)sender;

- (void)reloadGame;
- (void)reloadGameFromURL:(NSURL *)inRemoteURL;

- (void)startAnimation;
- (void)stopAnimation;

@end
