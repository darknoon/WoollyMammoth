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


@interface VideoCapture : NSObject
#if TARGET_OS_EMBEDDED
<AVCaptureVideoDataOutputSampleBufferDelegate> 
#endif
{
#if TARGET_OS_EMBEDDED
	AVCaptureSession *captureSession;
	AVCaptureInput  *input;
	AVCaptureVideoDataOutput  *output;
	AVCaptureDevice *cameraDevice;
#else			
	NSTimer *simulatorDebugTimer;
#endif
	BOOL capturing;
	
	GLuint textures[VideoCapture_NumTextures];
		
	//Swap between textures to reduce locking issues
	NSUInteger currentTexture; //This is the texture that was just written into
	BOOL textureWasRead;
	
#if DEBUG_TEXTURE_UPLOAD
	int logi;
	char log[10000];
#endif
}

@property (nonatomic, readonly) BOOL capturing;

+ (VideoCapture *)sharedCapture;

//Will block until AVFoundation is done processing
- (GLuint)getVideoTexture;

- (void)startCapture;
- (void)stopCapture;

@end
