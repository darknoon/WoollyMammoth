//
//  WMEngine.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/12/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WMPatch;
@class DNEAGLContext;

@interface WMEngine : NSObject {
	DNEAGLContext *renderContext;
	
	CFAbsoluteTime previousAbsoluteTime;
	CFAbsoluteTime t;
	
	UInt64 maxObjectId;
	NSMutableDictionary *patchesByKey;
	WMPatch *rootObject;
}

@property (nonatomic, retain, readonly) DNEAGLContext *renderContext;
@property (nonatomic, retain, readonly) WMPatch *rootObject;

- (NSString *)title;

- (WMPatch *)patchWithKey:(NSString *)inPatchKey;

- (void)start;

- (void)drawFrameInRect:(CGRect)inBounds;


@end
