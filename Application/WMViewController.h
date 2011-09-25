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

@class WMEngine;
@class WMPatch;
@class WMBundleDocument;
@class EAGLView;

@interface WMViewController : UIViewController <UIActionSheetDelegate>

//Designated initalizer for an existing document
- (id)initWithDocument:(WMBundleDocument *)inDocument;

//If you want to read from a file, you can load from a nib and use this:
@property (nonatomic, copy) NSURL *compositionURL;

@property (nonatomic, weak) IBOutlet EAGLView *eaglView;

@property (nonatomic, retain) WMBundleDocument *document;
@property (readonly, retain, readonly) WMEngine *engine;
@property (readonly, nonatomic, getter=isAnimating) BOOL animating;
@property (nonatomic) NSInteger animationFrameInterval;

- (UIImage *)screenshotImage;

- (void)startAnimation;
- (void)stopAnimation;

//For subclassers, do not call directly (the display link will handle this)
- (void)drawFrame;

@end
