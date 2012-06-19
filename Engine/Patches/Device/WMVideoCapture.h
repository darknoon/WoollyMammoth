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

@interface WMVideoCapture : WMPatch
#if TARGET_OS_EMBEDDED
<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, WMPatchEventSource> 
#endif
{
	WMImagePort *outputImage;
	WMAudioPort *outputAudio;
}

@property (nonatomic, readonly) BOOL capturing;

- (void)startCapture;
- (void)stopCapture;

@end
