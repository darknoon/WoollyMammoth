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

#define VideoCapture_NumTextures 2

#define USE_LOW_RES_CAMERA 0
//Otherwise, use RGBA
#define USE_BGRA 1
#define DEBUG_TEXTURE_UPLOAD 0

#import "WMPatch.h"

@class WMImagePort;
@class WMBooleanPort;
@class WMTexture2D;

@interface WMVideoCapture : WMPatch
#if TARGET_OS_EMBEDDED
<AVCaptureVideoDataOutputSampleBufferDelegate> 
#endif
{
	BOOL capturing;
	
	WMTexture2D *textures[VideoCapture_NumTextures];
		
	//Swap between textures to reduce locking issues
	NSUInteger currentTexture; //This is the texture that was just written into
	BOOL textureWasRead;
	
	BOOL useFrontCamera;
	
	WMBooleanPort *inputCapture;
	
	WMImagePort *outputImage;
	
#if TARGET_OS_EMBEDDED
	AVCaptureSession *captureSession;
	AVCaptureInput  *captureInput;
	AVCaptureVideoDataOutput  *dataOutput;
	AVCaptureDevice *cameraDevice;
#else			
	NSTimer *simulatorDebugTimer;
#endif
	
#if DEBUG_TEXTURE_UPLOAD
	int logi;
	char log[10000];
#endif
}

@property (nonatomic, readonly) BOOL capturing;

- (void)startCapture;
- (void)stopCapture;

@end
