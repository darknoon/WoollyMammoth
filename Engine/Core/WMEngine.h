//
//  WMEngine.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/12/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <GLKit/GLKMath.h>

@class WMPatch;
@class WMEAGLContext;
@class DNQCComposition;

extern NSString *const WMEngineInterfaceOrientationArgument;

@interface WMEngine : NSObject {
	WMEAGLContext *renderContext;
	
	CFAbsoluteTime previousAbsoluteTime;
	CFAbsoluteTime t;
		
	WMPatch *rootObject;
	NSMutableDictionary *compositionUserData;
}

- (id)initWithRootObject:(WMPatch *)inNode userData:(NSDictionary *)inUserData;

- (id)initWithComposition:(DNQCComposition *)inComposition;

+ (GLKMatrix4)cameraMatrixWithRect:(CGRect)inBounds;

@property (nonatomic, retain, readonly) WMEAGLContext *renderContext;
@property (nonatomic, retain, readonly) WMPatch *rootObject;

- (NSString *)title;

- (void)start;

- (void)drawFrameInRect:(CGRect)inBounds interfaceOrientation:(UIInterfaceOrientation)inInterfaceOrientation;


//For unit testing. No need to use directly!
- (NSArray *)executionOrderingOfChildren:(WMPatch *)inPatch;


@end
