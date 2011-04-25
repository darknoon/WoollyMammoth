//
//  WMEngine.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/12/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WMPatch;
@class WMEAGLContext;
@class DNQCComposition;

@interface WMEngine : NSObject {
	WMEAGLContext *renderContext;
	
	CFAbsoluteTime previousAbsoluteTime;
	CFAbsoluteTime t;
		
	WMPatch *rootObject;
	NSDictionary *compositionUserData;
}

- (id)initWithComposition:(DNQCComposition *)inComposition;

@property (nonatomic, retain, readonly) WMEAGLContext *renderContext;
@property (nonatomic, retain, readonly) WMPatch *rootObject;

- (NSString *)title;

- (void)start;

- (void)drawFrameInRect:(CGRect)inBounds;


@end
