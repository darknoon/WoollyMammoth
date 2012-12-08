//
//  WMViewController.h
//  NewTemplateTest
//
//  Created by Andrew Pouliot on 10/12/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import "WMEngine.h"

@class WMPatch;
@class WMBundleDocument;
@class WMView;

@interface WMViewController : UIViewController <UIActionSheetDelegate, WMEngineDelegate> {
}

//Designated initalizer for an existing document
- (id)initWithDocument:(WMBundleDocument *)inDocument;

//If you want to read from a file, you can load from a nib and use this:
@property (nonatomic, copy) NSURL *compositionURL;

@property (nonatomic, weak) IBOutlet WMView *eaglView;

@property (nonatomic) BOOL alwaysPortrait;

@property (nonatomic, strong) WMBundleDocument *document;
@property (readonly, strong, readonly) WMEngine *engine;
@property (readonly, nonatomic, getter=isAnimating) BOOL animating;
@property (nonatomic) NSInteger animationFrameInterval;

- (UIImage *)screenshotImage;

- (void)startAnimation;
- (void)stopAnimation;

//Override if you want WM to render in an orientation NOT the current -[UIViewController interfaceOrientation]
- (UIInterfaceOrientation)renderOrientation;

@end
