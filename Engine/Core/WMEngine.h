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
@class WMCompositionSerialization;
@class WMBundleDocument;

extern NSString *const WMEngineArgumentsInterfaceOrientationKey;
extern NSString *const WMEngineArgumentsDocumentKey;

@interface WMEngine : NSObject {
	CFAbsoluteTime previousAbsoluteTime;
	CFAbsoluteTime t;
	
	NSMutableDictionary *compositionUserData;
}

- (id)initWithBundle:(WMBundleDocument *)inDocument;

+ (GLKMatrix4)cameraMatrixWithRect:(CGRect)inBounds;

@property (nonatomic, strong, readonly) WMEAGLContext *renderContext;
@property (nonatomic, strong, readonly) WMPatch *rootObject;
@property (nonatomic, strong) WMBundleDocument *document;


- (NSString *)title;

- (void)start;

- (void)drawFrameInRect:(CGRect)inBounds interfaceOrientation:(UIInterfaceOrientation)inInterfaceOrientation;


//For unit testing. No need to use directly!
- (NSArray *)executionOrderingOfChildren:(WMPatch *)inPatch;


@end
