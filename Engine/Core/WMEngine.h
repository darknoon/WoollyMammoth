//
//  WMEngine.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/12/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <GLKit/GLKMath.h>

#import "WMPatchEventSource.h"

@class WMPatch;
@class WMEAGLContext;
@class WMCompositionSerialization;
@class WMComposition;
@class WMFramebuffer;
@protocol WMEngineDelegate;

extern NSString *const WMEngineArgumentsInterfaceOrientationKey;
extern NSString *const WMEngineArgumentsOutputDimensionsKey;
#if TARGET_OS_IPHONE
extern NSString *const WMEngineArgumentsCompositionKey;
#endif

@interface WMEngine : NSObject <WMPatchEventDelegate> //Recieve events from render output or camera input

- (id)initWithRootPatch:(WMPatch *)inPatch;
- (id)initWithBundle:(WMComposition *)inDocument;

@property (nonatomic, readonly) NSUInteger frameNumber;

@property (nonatomic, readonly) CFAbsoluteTime previousAbsoluteTime;
@property (nonatomic, readonly) CFAbsoluteTime t;

@property (nonatomic, strong) WMEAGLContext *renderContext;
@property (nonatomic, strong, readonly) WMPatch *rootObject;
@property (nonatomic, strong) WMComposition *document;

@property (nonatomic, strong) WMFramebuffer *renderFramebuffer;

@property (nonatomic, weak) id<WMEngineDelegate> delegate;

@property (nonatomic, readonly) double frameRate;
@property (nonatomic, readonly) double frameDuration;

//Edit the node graph between these calls.
//Currently just affects the event source, but could have more effects in the future
- (void)beginConfiguration;
- (void)commitConfiguration;

//Should be a WMVideoCapture (new frame)
//This is discovered when you call -start
@property (nonatomic, strong) WMPatch<WMPatchEventSource> *eventSource;

@property (nonatomic) CGRect frame;
@property (nonatomic) UIInterfaceOrientation interfaceOrientation;

- (void)start;
- (void)stop;

//- (void)drawFrameInRect:(CGRect)inBounds interfaceOrientation:(UIInterfaceOrientation)inInterfaceOrientation;

//For unit testing. No need to use directly!
- (NSArray *)executionOrderingOfChildren:(WMPatch *)inPatch;

@end


@protocol WMEngineDelegate <NSObject>
//TODO: @optional

//Set frame, interfaceOrientation, framebuffer
- (BOOL)engineShouldRenderFrame:(WMEngine *)engine;
- (void)engineDidRenderFrame:(WMEngine *)engine;

@end
