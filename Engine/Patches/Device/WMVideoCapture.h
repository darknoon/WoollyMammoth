//
//  VideoCapture.h
//  CaptureTest
//
//  Created by Andrew Pouliot on 8/12/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AVFoundation/AVFoundation.h>

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import "WMPatch.h"

@class WMImagePort;
@class WMBooleanPort;
@class WMTexture2D;

@interface WMVideoCapture : WMPatch <WMPatchEventSource>

@property (nonatomic) NSTimeInterval targetFramerate;

@property (nonatomic, copy) NSString *sessionPreset;

@property (nonatomic, readonly) WMVector2Port *inputFocusPointOfInterest;
@property (nonatomic, readonly) WMBooleanPort *inputUseFrontCamera;
@property (nonatomic, readonly) WMBooleanPort *inputEnableTorch;

@property (nonatomic, readonly) WMImagePort *outputImage;
@property (nonatomic, readonly) WMAudioPort *outputAudio;
@property (nonatomic, readonly) WMBooleanPort *outputFocusing;

@property (nonatomic, readonly) BOOL capturing;

- (void)startCapture;
- (void)stopCapture;

@end
