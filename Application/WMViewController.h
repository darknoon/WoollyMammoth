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
@class WMPatch;

@interface WMViewController : UIViewController <UIActionSheetDelegate>

@property (readonly, retain) WMEngine *engine;
@property (readonly, nonatomic, getter=isAnimating) BOOL animating;
@property (nonatomic) NSInteger animationFrameInterval;
@property (nonatomic, retain) IBOutlet WMDebugViewController *debugViewController;

- (id)initWithRootPatch:(WMPatch *)inPatch;

- (UIImage *)screenshotImage;

- (IBAction)showDebug:(id)sender;

- (void)reloadEngine;
- (void)reloadEngineFromURL:(NSURL *)inURL;

- (void)startAnimation;
- (void)stopAnimation;

//For subclassers, do not call directly (the display link or timer will handle this)
- (void)drawFrame;

@end
