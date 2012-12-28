//
//  VideoCapture.m
//  CaptureTest
//
//  Created by Andrew Pouliot on 8/12/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "WMVideoCapture.h"

//Device
#if (TARGET_OS_IPHONE && TARGET_OS_EMBEDDED)
#define USE_CVTEXTURE_2D 1
#define FAKE_CAPTURE_CONTENT 0

//Simulator
#elif TARGET_OS_IPHONE
#define FAKE_CAPTURE_CONTENT 1
#define USE_CVTEXTURE_2D 0

//Mac
#elif TARGET_OS_MAC
#define FAKE_CAPTURE_CONTENT 0
#define USE_CVTEXTURE_2D 0

#endif

#import <CoreVideo/CoreVideo.h>
#if TARGET_OS_IPHONE
#import <CoreVideo/CVOpenGLESTextureCache.h>
#elif TARGET_OS_MAC
#import <CoreVideo/CVOpenGLTextureCache.h>
#endif

#import "WMEAGLContext.h"
#import "WMTexture2D.h"
#import "WMCVTexture2D.h"

#import "WMAudioBuffer.h"

#import "WMBooleanPort.h"
#import "WMImagePort.h"
#import "WMAudioPort.h"

//For the interfaceOrientation argument
#import "WMEngine.h"

#if !FAKE_CAPTURE_CONTENT
@interface WMVideoCapture ()
<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>
@end
#endif

@implementation WMVideoCapture {
	BOOL capturing;
	
	BOOL useFrontCamera;
	
	UIImageOrientation currentVideoOrientation;
	
	WMTexture2D *mostRecentTexture;
	WMAudioBuffer *mostRecentAudioBuffer;
	
	WMEAGLContext *_context;

#if !FAKE_CAPTURE_CONTENT
	
	dispatch_queue_t videoCaptureQueue;

	AVCaptureSession *captureSession;
	AVCaptureInput *captureVideoInput;
	AVCaptureInput *captureAudioInput;

	AVCaptureDevice *cameraDevice;
	AVCaptureDevice *microphoneDevice;

	AVCaptureVideoDataOutput *videoDataOutput;
	AVCaptureAudioDataOutput *audioDataOutput;
	
	CVOGLTexCacheRef_t textureCache;
#else
	NSTimer *simulatorDebugTimer;
#endif
	
}

@synthesize eventDelegate = _eventDelegate;
@synthesize capturing;
@synthesize eventDelegatePaused = _eventDelegatePaused;
@synthesize outputImage = _outputImage;
@synthesize outputAudio = _outputAudio;

+ (void)load;
{
	@autoreleasepool {
		[self registerPatchClass];
	}
}


- (id) initWithPlistRepresentation:(id)inPlist {
	self = [super initWithPlistRepresentation:inPlist];
	if (!self) return self; 
	
	_sessionPreset = AVCaptureSessionPreset640x480;
	_eventDelegatePaused = YES; //paused, so setting not paused triggers setup & go
	
	return self;
}

+ (id)defaultValueForInputPortKey:(NSString *)inKey;
{
	if ([inKey isEqualToString:KVC([WMVideoCapture new], inputFocusPointOfInterest)]) {
		//Default to center like the system
		return [NSValue valueWithBytes:&(GLKVector2){0.5, 0.5} objCType:@encode(GLKVector2)];
	}
	return nil;
}

+ (NSString *)category;
{
    return WMPatchCategoryDevice;
}

- (BOOL)setup:(WMEAGLContext *)context;
{	
	_context = context;
	
	GL_CHECK_ERROR;
	
#if !FAKE_CAPTURE_CONTENT
	videoCaptureQueue = dispatch_queue_create([[NSString stringWithFormat:@"com.darknoon.%@.videoCaptureQueue", [self class]] UTF8String], DISPATCH_QUEUE_SERIAL);
	dispatch_set_target_queue(videoCaptureQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));

#if TARGET_OS_IPHONE
	CVReturn result = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, context, NULL, &textureCache);
	if (result != kCVReturnSuccess) {
		NSLog(@"Error creating CVOpenGLESTextureCache: %d", result);
	}
#elif TARGET_OS_MAC
	
	CFDictionaryRef cacheAttributes = nil;
	CFDictionaryRef textureAttributes = nil;
	CGLPixelFormatObj pixFormat = NULL;
#if 0
	//Try to get an BRGA888 pixel format...
	const CGLPixelFormatAttribute attribs[] = {
		kCGLPFAColorSize, 8,
		0,0,
	};
	GLint npix;
	CGLError pixelFormatError = CGLChoosePixelFormat(attribs, &pixFormat, &npix);
	if (npix > 1) {
		NSLog(@"Found %d pixel formats", npix);
	}
	if (pixelFormatError != kCGLNoError) {
		NSLog(@"Error finding pixel format for capture: %s", CGLErrorString(kCGLNoError));
	}
#else
	pixFormat = CGLGetPixelFormat(_context.openGLContext.CGLContextObj);
#endif
	CVReturn result = CVOpenGLTextureCacheCreate(kCFAllocatorDefault, cacheAttributes, _context.openGLContext.CGLContextObj, pixFormat, textureAttributes, &textureCache);
	if (result != kCVReturnSuccess) {
		NSLog(@"Error creating CVOpenGLTextureCache: %d", result);
		return NO;
	}
	
#endif
	
#endif

	return YES;
}

- (void)cleanup:(WMEAGLContext *)context;
{
	[self stopCapture];
#if !FAKE_CAPTURE_CONTENT
	videoCaptureQueue = NULL;
	
	if (textureCache)
		CFRelease(textureCache);
	textureCache = NULL;

#endif
	
	mostRecentTexture = nil;

	
	[super cleanup:context];
	_context = nil;
}

#if !FAKE_CAPTURE_CONTENT
- (BOOL)configureForVideoInputDevice:(AVCaptureDevice *)device error:(NSError **)outError;
{
	NSError *error = nil;
	

	//Remove any old camera device
	if (captureVideoInput) {
		[captureSession removeInput:captureVideoInput];
		captureVideoInput = nil;
	}
	cameraDevice = device;
	DLog(@"Configuring capture for video device: %@", device);
	
	if (cameraDevice) {
		if ([cameraDevice supportsAVCaptureSessionPreset:_sessionPreset]) {
			[captureSession setSessionPreset:_sessionPreset];
		} else {
			NSLog(@"ERROR: could not set an appropriate session preset for capturing from video device: %@", device);
			return NO;
		}
		

		captureVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:cameraDevice error:&error];
				
		if (captureVideoInput) {
			[captureSession addInput:captureVideoInput];
		} else {
			NSLog(@"Error making a video input from device. %@", error);
			if (outError) *outError = error;
			return NO;
		}
	} else {
		return NO;
	}
	
	return YES;
}

- (BOOL)configureForAudioInputDevice:(AVCaptureDevice *)device error:(NSError **)outError;
{
	NSError *error = nil;

	if (captureAudioInput) {
		[captureSession removeInput:captureAudioInput];
		captureAudioInput = nil;
	}
	if (!device) {
		NSLog(@"Error getting microphone. Continuing...");
		return NO;
	}
	
	microphoneDevice = device;
	
	if (microphoneDevice) {
		captureAudioInput = [[AVCaptureDeviceInput alloc] initWithDevice:microphoneDevice error:&error];
		if (captureAudioInput) {
			[captureSession addInput:captureAudioInput];
		} else {
			NSLog(@"Error making an audio input from device. %@", error);
			if (outError) *outError = error;
			return NO;
		}
	} else {
		return NO;
	}
	
	return YES;
}
#endif

- (void)startCapture;
{
	//TODO: make this hack less hacky
	if (capturing) return;
		
#if !FAKE_CAPTURE_CONTENT
	captureSession = [[AVCaptureSession alloc] init];
	
	[captureSession beginConfiguration];

	NSError *error = nil;
	
#if TARGET_OS_EMBEDDED
	for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
		if (device.position == (useFrontCamera ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack)) {
			[self configureForVideoInputDevice:device error:&error];
			break;
		}
	}
#elif TARGET_OS_MAC
	[self configureForVideoInputDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo] error:&error];
#endif
	
	[self configureForAudioInputDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio] error:&error];
	
	
	videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
	DLog(@"Capture pixel formats in order of decreasing efficency: %@", [[videoDataOutput availableVideoCVPixelFormatTypes] componentsJoinedByString:@", "]);
	
	if (!videoDataOutput) {
		NSLog(@"Error making video output.");
		return;
	}
	
	[videoDataOutput setVideoSettings:@{
	 	(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)
	 }];
	[videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
	
	[videoDataOutput setSampleBufferDelegate:self queue:videoCaptureQueue];
	
	audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
	[audioDataOutput setSampleBufferDelegate:self queue:videoCaptureQueue];
	if (!audioDataOutput) {
		NSLog(@"Error making audio output.");
		return;
	}
	
	[captureSession addOutput:videoDataOutput];
	[captureSession addOutput:audioDataOutput];
	
	ZAssert(videoDataOutput.connections.count > 0, @"AVCaptureSession did not hook the videoDataOutput to any connections");
	AVCaptureConnection *videoDataConnection = [videoDataOutput.connections objectAtIndex:0];
	if (self.targetFramerate > 0) {
		videoDataConnection.videoMinFrameDuration = CMTimeMakeWithSeconds(1.0 / _targetFramerate, 600);
	}

	[captureSession commitConfiguration];

	[captureSession startRunning];
#else
	if (!simulatorDebugTimer)
		simulatorDebugTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/30.0 target:self selector:@selector(simulatorUploadTexture) userInfo:nil repeats:YES];

#endif	

	capturing = YES;
}

- (void)stopCapture;
{
#if !FAKE_CAPTURE_CONTENT
	[captureSession stopRunning];
	captureSession = nil;
	captureVideoInput = nil;
	videoDataOutput = nil;
	cameraDevice = nil;
	
	mostRecentTexture = nil;
	
#else
	[simulatorDebugTimer invalidate];
	simulatorDebugTimer = nil;
#endif
	
	capturing = NO;
}

#if !FAKE_CAPTURE_CONTENT

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer 
	   fromConnection:(AVCaptureConnection *)connection;
{		
	dispatch_sync(dispatch_get_main_queue(), ^{
		if (capturing) {
			
			if (captureOutput == audioDataOutput) {
				
				//Better to drop than accumulate a ton!
				if (mostRecentAudioBuffer.sampleBuffers.count > 10) {
					mostRecentAudioBuffer = nil;
					DLog(@"ERROR: audio buffer overflow (video underflow) delegate: %@", self.eventDelegate);
				}
				
				mostRecentAudioBuffer = mostRecentAudioBuffer ? [mostRecentAudioBuffer bufferByAppendingSampleBuffer:sampleBuffer] : [[WMAudioBuffer alloc] initWithCMSampleBuffer:sampleBuffer];
				
			} else if (captureOutput == videoDataOutput) {

#if TARGET_OS_IPHONE
				BOOL applicationCanUseOpenGL = [UIApplication sharedApplication].applicationState != UIApplicationStateBackground;
				if (!applicationCanUseOpenGL) {
					NSLog(@"Camera update when app is in background");
				}
#endif
				[WMEAGLContext setCurrentContext:_context];
				
				//Get buffer info
				CVPixelBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
				
				//NSLog(@"Is ready: %@ samples:%uld sampleSize:%d width:%d height:%d bytes/row:%d baseAddr:%x", ready ? @"Y" : @"N", numsamples, sampleSize, width, height, bytesPerRow, baseAddress);

				GL_CHECK_ERROR;
#if USE_CVTEXTURE_2D
				WMCVTexture2D *texture = [[WMCVTexture2D alloc] initWithCVImageBuffer:imageBuffer inTextureCache:textureCache format:kWMTexture2DPixelFormat_BGRA8888 use:@"Video Capture"];
				texture.orientation = currentVideoOrientation;
				
#else
				CVPixelBufferLockBaseAddress(imageBuffer, 0);
				void *baseAddr = CVPixelBufferGetBaseAddress(imageBuffer);
				CGSize size = CVImageBufferGetEncodedSize(imageBuffer);

				WMTexture2D *texture = [[WMTexture2D alloc] initWithData:baseAddr pixelFormat:kWMTexture2DPixelFormat_BGRA8888 pixelsWide:size.width pixelsHigh:size.height contentSize:size orientation:currentVideoOrientation];
				CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
#endif
				GL_CHECK_ERROR;
				
				mostRecentTexture = texture;
				
				GL_CHECK_ERROR;
				
				if (!self.eventDelegatePaused) {
					[self.eventDelegate patchGeneratedUpdateEvent:self atTime:CACurrentMediaTime()];
				}
			}
			
		}
		
	});
}

#else

- (void)simulatorUploadTexture;
{
	[WMEAGLContext setCurrentContext:_context];
	//Get the texture ready
	
	unsigned width = 320;
	unsigned height = 240;
	
	static unsigned char ppp;
	
	//Initialize the buffer
	unsigned char *buffer = malloc(4 * width * height);
	for (int y=0, i=0; y<height; y++) {
		for (int x=0; x<width; x++, i++) {
			buffer[4*i + 0] = 255 - ppp;
			buffer[4*i + 1] = 2 * ppp + x;
			buffer[4*i + 2] = 2 * y;
			buffer[4*i + 3] = 255;
		}
	}
	ppp++;
	
	mostRecentTexture = [[WMTexture2D alloc] initWithData:buffer pixelFormat:kWMTexture2DPixelFormat_BGRA8888 pixelsWide:width pixelsHigh:height contentSize:(CGSize){width, height} orientation:currentVideoOrientation];
	
	free(buffer);
	
	if (!self.eventDelegatePaused)
		[self.eventDelegate patchGeneratedUpdateEvent:self atTime:CACurrentMediaTime()];
}

#endif

- (void)setEventDelegatePaused:(BOOL)eventDelegatePaused;
{
	if (_eventDelegatePaused != eventDelegatePaused) {
		if (eventDelegatePaused) {
			[self stopCapture];
		} else {
			[self startCapture];
		}
		
		_eventDelegatePaused = eventDelegatePaused;
	}
}

- (BOOL)execute:(WMEAGLContext *)context time:(double)time arguments:(NSDictionary *)args;
{
	UIInterfaceOrientation interfaceOrientation = [[args objectForKey:WMEngineArgumentsInterfaceOrientationKey] intValue];
	
#if !FAKE_CAPTURE_CONTENT
	//Switich camera devices
	if (capturing && useFrontCamera != self.inputUseFrontCamera.value) {
		useFrontCamera = self.inputUseFrontCamera.value;
		//Recreate the input
		[captureSession beginConfiguration];
		for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
			if (device.position == (useFrontCamera ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack)) {
				NSError *error = nil;
				if (![self configureForVideoInputDevice:device error:&error]) {
					NSLog(@"Error configuring video input: %@", error);
				}
				
				break;
			}
		}
		[captureSession commitConfiguration];
	}
	useFrontCamera = self.inputUseFrontCamera.value;
#endif
	
	if (useFrontCamera) {
		//TODO: this :)
		switch (interfaceOrientation) {
			case UIInterfaceOrientationPortrait:
				currentVideoOrientation = UIImageOrientationLeft;
				break;
			case UIInterfaceOrientationPortraitUpsideDown:
				currentVideoOrientation = UIImageOrientationRight;
				break;
			case UIInterfaceOrientationLandscapeLeft:
				currentVideoOrientation = UIImageOrientationDown;
				break;
			case UIInterfaceOrientationLandscapeRight:
				currentVideoOrientation = UIImageOrientationUp;
				break;
			default:
				break;
		}

	} else {
		//TODO: determine the correct values here
		switch (interfaceOrientation) {
			case UIInterfaceOrientationPortrait:
				currentVideoOrientation = UIImageOrientationLeft;
				break;
			case UIInterfaceOrientationPortraitUpsideDown:
				currentVideoOrientation = UIImageOrientationRight;
				break;
			case UIInterfaceOrientationLandscapeLeft:
				currentVideoOrientation = UIImageOrientationDown;
				break;
			case UIInterfaceOrientationLandscapeRight:
				currentVideoOrientation = UIImageOrientationUp;
				break;
			default:
				break;
		}
	}
	
	if (!capturing) {
		[self startCapture];
	}
	
#if TARGET_OS_EMBEDDED
	//Set torch mode if supported
	if (cameraDevice.torchAvailable && (_inputEnableTorch.value != (cameraDevice.torchMode == AVCaptureTorchModeOn)) ) {
		NSError *lockError;
		BOOL locked = [cameraDevice lockForConfiguration:&lockError];
		if (locked) {
			cameraDevice.torchMode = _inputEnableTorch.value ? AVCaptureTorchModeOn : AVCaptureTorchModeOff;
			
			[cameraDevice unlockForConfiguration];
		}
	}
#endif
	
	//Set focus point of interest if supported
#if !FAKE_CAPTURE_CONTENT
	if (cameraDevice.focusPointOfInterestSupported) {
		CGPoint inputFocusPoint = CGPointFromGLKVector2(_inputFocusPointOfInterest.v);
		CGPoint currentFocusPoint = cameraDevice.focusPointOfInterest;
		if (!CGPointEqualToPoint(inputFocusPoint, currentFocusPoint)) {
			NSError *lockError;
			BOOL locked = [cameraDevice lockForConfiguration:&lockError];
			if (locked) {
				NSLog(@"Setting camera focus POI to : %.2f %.2f", inputFocusPoint.x, inputFocusPoint.y);
				cameraDevice.focusPointOfInterest = inputFocusPoint;
				cameraDevice.focusMode = AVCaptureFocusModeAutoFocus;
				[cameraDevice unlockForConfiguration];
				
				//This is a hack to prevent us thinking we're not focusing...
			} else {
				DLog(@"Camera device lock failed: %@", lockError);
			}
		}
	}
	_outputFocusing.value = cameraDevice.focusMode == AVCaptureFocusModeAutoFocus;
#endif

	_outputImage.image = mostRecentTexture;
	_outputAudio.objectValue = mostRecentAudioBuffer;
	mostRecentAudioBuffer = nil;
	
	GL_CHECK_ERROR;
	
#if !FAKE_CAPTURE_CONTENT && TARGET_OS_IPHONE
	CVOpenGLESTextureCacheFlush(textureCache, 0);
#elif !FAKE_CAPTURE_CONTENT && TARGET_OS_MAC
	CVOpenGLTextureCacheFlush(textureCache, 0);
#endif
	
	GL_CHECK_ERROR;

	return YES;
}

#if TARGET_OS_IPHONE
- (UIColor *)editorColor;
{
	return [UIColor colorWithRed:0.798f green:0.349f blue:0.061f alpha:0.8f];
}
#elif TARGET_OS_MAC
- (CGColorRef)editorColor;
{
	return [NSColor colorWithDeviceRed:0.798f green:0.349f blue:0.061f alpha:0.8f].CGColor;
}
#endif

@end
