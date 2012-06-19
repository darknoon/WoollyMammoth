//
//  VideoCapture.m
//  CaptureTest
//
//  Created by Andrew Pouliot on 8/12/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "WMVideoCapture.h"

#import <CoreVideo/CoreVideo.h>
#import <CoreVideo/CVOpenGLESTextureCache.h>

#import "WMEAGLContext.h"
#import "WMTexture2D.h"
#import "WMCVTexture2D.h"

#import "WMAudioBuffer.h"

#import "WMBooleanPort.h"
#import "WMImagePort.h"
#import "WMAudioPort.h"

//For the interfaceOrientation argument
#import "WMEngine.h"

@implementation WMVideoCapture {
	BOOL capturing;
	
	BOOL useFrontCamera;
	
	UIImageOrientation currentVideoOrientation;
	
	//TODO: yeah, this is dumb, use the camera as an event source and only process each frame once...
	WMTexture2D *mostRecentTexture;
	WMAudioBuffer *mostRecentAudioBuffer;
	
	WMEAGLContext *_context;

#if TARGET_OS_EMBEDDED
	
	dispatch_queue_t videoCaptureQueue;
	dispatch_queue_t audioCaptureQueue;

	AVCaptureSession *captureSession;
	AVCaptureInput *captureVideoInput;
	AVCaptureInput *captureAudioInput;

	AVCaptureDevice *cameraDevice;
	AVCaptureDevice *microphoneDevice;

	AVCaptureVideoDataOutput *videoDataOutput;
	AVCaptureAudioDataOutput *audioDataOutput;
	
	CVOpenGLESTextureCacheRef textureCache;
#else
	NSTimer *simulatorDebugTimer;
#endif
	
}

@synthesize eventDelegate = _eventDelegate;
@synthesize capturing;
@synthesize eventDelegatePaused = _eventDelegatePaused;

+ (void)load;
{
	@autoreleasepool {
		[self registerPatchClass];
	}
}


- (id) initWithPlistRepresentation:(id)inPlist {
	self = [super initWithPlistRepresentation:inPlist];
	if (!self) return self; 
		
	return self;
}

+ (id)defaultValueForInputPortKey:(NSString *)inKey;
{
	if ([inKey isEqualToString:@"inputCapture"]) {
		return [NSNumber numberWithBool:YES];
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
	
#if TARGET_OS_EMBEDDED
	videoCaptureQueue = dispatch_queue_create([[NSString stringWithFormat:@"com.darknoon.%@.videoCaptureQueue", [self class]] UTF8String], DISPATCH_QUEUE_SERIAL);
	dispatch_set_target_queue(videoCaptureQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
	
	audioCaptureQueue = dispatch_queue_create([[NSString stringWithFormat:@"com.darknoon.%@.audioCaptureQueue", [self class]] UTF8String], DISPATCH_QUEUE_SERIAL);
	dispatch_set_target_queue(audioCaptureQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
	
	CVReturn result = CVOpenGLESTextureCacheCreate(NULL, NULL, (__bridge void *)context, NULL, &textureCache);
	if (result != kCVReturnSuccess) {
		NSLog(@"Error creating CVOpenGLESTextureCache");
	}
	
#endif
	
	[self startCapture];

	return YES;
}

- (void)cleanup:(WMEAGLContext *)context;
{
	[self stopCapture];
#if TARGET_OS_EMBEDDED
	if (videoCaptureQueue)
		dispatch_release(videoCaptureQueue);
	videoCaptureQueue = NULL;
	if (audioCaptureQueue)
		dispatch_release(audioCaptureQueue);
	audioCaptureQueue = NULL;
#endif
	
	mostRecentTexture = nil;
	
	[super cleanup:context];
	_context = nil;
}


- (void)startCapture;
{
	//TODO: make this hack less hacky
	if (capturing) return;
		
#if TARGET_OS_EMBEDDED
	captureSession = [[AVCaptureSession alloc] init];

	[captureSession setSessionPreset:AVCaptureSessionPreset640x480];

	NSError *error = nil;
	
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	DLog(@"Devices: %@", devices);
	
	//Look for back camera
	for (AVCaptureDevice *device in devices) {
		if (device.position == (useFrontCamera ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack)) {
			DLog(@"Video capture from device: %@", device);
			cameraDevice = device;
			break;
		}
	}
	
	microphoneDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
	if (!microphoneDevice) {
		NSLog(@"Error getting microphone. Continuing...");
	}
	
	captureVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:cameraDevice error:&error];
	if (!captureVideoInput) {
		NSLog(@"Error making a video input from device. %@", error);
		return;
	}
	
	captureAudioInput = [[AVCaptureDeviceInput alloc] initWithDevice:microphoneDevice error:&error];
	if (!captureAudioInput) {
		NSLog(@"Error making an audio input from device. %@", error);
		return;
	}
	
	videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
	DLog(@"Capture pixel formats in order of decreasing efficency: %@", [[videoDataOutput availableVideoCVPixelFormatTypes] componentsJoinedByString:@", "]);
	
	if (!videoDataOutput) {
		NSLog(@"Error making video output.");
		return;
	}
	NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
								   [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA], (id)kCVPixelBufferPixelFormatTypeKey,
								   [NSNumber numberWithBool:YES], (id)kCVPixelBufferOpenGLCompatibilityKey, nil];
	
	[videoDataOutput setVideoSettings:videoSettings];	
	[videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
	
	[videoDataOutput setSampleBufferDelegate:self queue:videoCaptureQueue];
	
	audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
	[audioDataOutput setSampleBufferDelegate:self queue:audioCaptureQueue];
	if (!audioDataOutput) {
		NSLog(@"Error making audio output.");
		return;
	}
	
	[captureSession addInput:captureVideoInput];
	[captureSession addInput:captureAudioInput];
	[captureSession addOutput:videoDataOutput];
	[captureSession addOutput:audioDataOutput];
	
	[captureSession startRunning];
#else
	if (!simulatorDebugTimer)
		simulatorDebugTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/30.0 target:self selector:@selector(simulatorUploadTexture) userInfo:nil repeats:YES];

#endif	

	capturing = YES;
}

- (void)stopCapture;
{
#if TARGET_OS_EMBEDDED
	[captureSession stopRunning];
	captureSession = nil;
	captureVideoInput = nil;
	videoDataOutput = nil;
	cameraDevice = nil;
	
	mostRecentTexture = nil;

	if (textureCache)
		CFRelease(textureCache);
	textureCache = NULL;
	
#else
	[simulatorDebugTimer invalidate];
	simulatorDebugTimer = nil;
#endif
	
	capturing = NO;
}

#if TARGET_OS_EMBEDDED

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer 
	   fromConnection:(AVCaptureConnection *)connection;
{		
	dispatch_sync(dispatch_get_main_queue(), ^{
		if (capturing) {
			
			if (captureOutput == audioDataOutput) {
				
				mostRecentAudioBuffer = mostRecentAudioBuffer ? [mostRecentAudioBuffer bufferByAppendingSampleBuffer:sampleBuffer] : [[WMAudioBuffer alloc] initWithCMSampleBuffer:sampleBuffer];
				
			} else if (captureOutput == videoDataOutput) {
				//Get buffer info
				CVPixelBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
				
				//NSLog(@"Is ready: %@ samples:%uld sampleSize:%d width:%d height:%d bytes/row:%d baseAddr:%x", ready ? @"Y" : @"N", numsamples, sampleSize, width, height, bytesPerRow, baseAddress);

				GL_CHECK_ERROR;
				
				WMCVTexture2D *texture = [[WMCVTexture2D alloc] initWithCVImageBuffer:imageBuffer inTextureCache:textureCache format:kWMTexture2DPixelFormat_BGRA8888];
				texture.orientation = currentVideoOrientation;
				
				GL_CHECK_ERROR;
				
				mostRecentTexture = texture;
				
				GL_CHECK_ERROR;
				
				
				if (!self.eventDelegatePaused)
					[self.eventDelegate patchGeneratedUpdateEvent:self atTime:CACurrentMediaTime()];
			}
			
		}
		
	});
}

#else

- (void)simulatorUploadTexture;
{
	[WMEAGLContext setCurrentContext:_context];
	//Get the texture ready
	
	unsigned width = 640;
	unsigned height = 480;
	
	static unsigned char ppp;
	
	//Initialize the buffer
	unsigned char *buffer = malloc(4 * width * height);
	for (int y=0, i=0; y<height; y++) {
		for (int x=0; x<width; x++, i++) {
			buffer[4*i + 0] = 255 - ppp;
			buffer[4*i + 1] = ppp + x;
			buffer[4*i + 2] = y;
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
//		if (eventDelegatePaused) {
//			[self stopCapture];
//		} else {
//			[self startCapture];
//		}
		
		_eventDelegatePaused = eventDelegatePaused;
	}
}

- (BOOL)execute:(WMEAGLContext *)context time:(double)time arguments:(NSDictionary *)args;
{
	useFrontCamera = [[args objectForKey:@"com.darknoon.WMVideoCapture.useFront"] boolValue];
	
	UIInterfaceOrientation interfaceOrientation = [[args objectForKey:WMEngineArgumentsInterfaceOrientationKey] intValue];
	
	BOOL isPhone = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone;
	
	if (isPhone) {
		if (useFrontCamera) {
			//TODO: this :)
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
	} else {
		if (useFrontCamera) {
			//TODO: this :)
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
		
	}
	
	if (!capturing) {
		[self startCapture];
	}
	
	outputImage.image = mostRecentTexture;
	outputAudio.objectValue = mostRecentAudioBuffer;
	mostRecentAudioBuffer = nil;
	
	GL_CHECK_ERROR;
	
#if TARGET_OS_EMBEDDED
	CVOpenGLESTextureCacheFlush(textureCache, 0);
#endif
	
	GL_CHECK_ERROR;

	return YES;
}

- (UIColor *)editorColor;
{
	return [UIColor colorWithRed:0.798f green:0.349f blue:0.061f alpha:0.8f];
}

@end
