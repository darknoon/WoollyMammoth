//
//  WMViewController.h
//  NewTemplateTest
//
//  Created by Andrew Pouliot on 10/12/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "WMRenderCommon.h"
#import "WMEngine.h"

@class WMPatch;
@class WMComposition;
@class WMView;

//TODO: rename WMCompositionViewController?
#if TARGET_OS_IPHONE
@interface WMViewController : UIViewController <WMEngineDelegate>
#elif TARGET_OS_MAC
@interface WMViewController : NSViewController <WMEngineDelegate>
#endif
//Designated initalizer for an existing document
- (id)initWithComposition:(WMComposition *)inDocument;

//If you want to read from a file, you can load from a nib and use this:
@property (nonatomic, copy) NSURL *compositionURL;

@property (nonatomic, weak) IBOutlet WMView *eaglView;

@property (nonatomic) BOOL alwaysPortrait;

@property (nonatomic, strong) WMComposition *document;
@property (readonly, strong, readonly) WMEngine *engine;
@property (readonly, nonatomic, getter=isAnimating) BOOL animating;
@property (nonatomic) NSInteger animationFrameInterval;

#if TARGET_OS_IPHONE
- (UIImage *)screenshotImage;
#endif

- (void)startAnimation;
- (void)stopAnimation;

#if TARGET_OS_IPHONE
//Override if you want WM to render in an orientation NOT the current -[UIViewController interfaceOrientation]
- (UIInterfaceOrientation)renderOrientation;
#else
@property (nonatomic) UIInterfaceOrientation renderOrientation;
#endif
@end
