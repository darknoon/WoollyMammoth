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

#import "WMBooleanPort.h"
#import "WMImagePort.h"

//For the interfaceOrientation argument
#import "WMEngine.h"

@implementation WMVideoCapture {
	BOOL capturing;
	
	BOOL useFrontCamera;
	
	UIImageOrientation currentVideoOrientation;
	
	WMTexture2D *mostRecentTexture;

#if TARGET_OS_EMBEDDED
	
	dispatch_queue_t videoCaptureQueue;
	

	AVCaptureSession *captureSession;
	AVCaptureInput  *captureInput;
	AVCaptureVideoDataOutput  *dataOutput;
	AVCaptureDevice *cameraDevice;
	
	CVOpenGLESTextureCacheRef textureCache;
#else			
	NSTimer *simulatorDebugTimer;
#endif
	
}

@synthesize capturing;

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
	GL_CHECK_ERROR;
	
#if TARGET_OS_EMBEDDED
	NSString *str = [NSString stringWithFormat:@"com.darknoon.%@.videoCaptureQueue", [self class]];
	videoCaptureQueue = dispatch_queue_create([str UTF8String], DISPATCH_QUEUE_SERIAL);
	dispatch_set_target_queue(videoCaptureQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));

	CVReturn result = CVOpenGLESTextureCacheCreate(NULL, NULL, (__bridge void *)context, NULL, &textureCache);
	if (result != kCVReturnSuccess) {
		NSLog(@"Error creating CVOpenGLESTextureCache");
	}
	
#endif
	
	return YES;
}

- (void)cleanup:(WMEAGLContext *)context;
{
	[self stopCapture];
#if TARGET_OS_EMBEDDED
	if (videoCaptureQueue)
		dispatch_release(videoCaptureQueue);
	videoCaptureQueue = NULL;
#endif
	
	mostRecentTexture = nil;
	
	[super cleanup:context];
}


- (void)startCapture;
{
	//TODO: make this hack less hacky
	if (capturing) return;
		
#if TARGET_OS_EMBEDDED
	captureSession = [[AVCaptureSession alloc] init];

#if USE_LOW_RES_CAMERA
	[captureSession setSessionPreset:AVCaptureSessionPresetLow];
#else
	[captureSession setSessionPreset:AVCaptureSessionPresetMedium];
#endif	
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
	
	captureInput = [[AVCaptureDeviceInput alloc] initWithDevice:cameraDevice error:&error];
	
	if (!captureInput) {
		NSLog(@"Error making an input from device. %@", error);
		return;
	}
	
	dataOutput = [[AVCaptureVideoDataOutput alloc] init];
	if (!dataOutput) {
		NSLog(@"Error making output.");
		return;
	}
	NSDictionary* videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
								   [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA], (id)kCVPixelBufferPixelFormatTypeKey,
								   [NSNumber numberWithBool:YES], (id)kCVPixelBufferOpenGLCompatibilityKey, nil];
	
	[dataOutput setVideoSettings:videoSettings];	
	[dataOutput setAlwaysDiscardsLateVideoFrames:YES];
	//1.0 / 60.0 seconds

	[dataOutput setSampleBufferDelegate:self queue:videoCaptureQueue];
	
	[captureSession addInput:captureInput];
	[captureSession addOutput:dataOutput];
	[captureSession startRunning];
#else
	if (!simulatorDebugTimer)
		simulatorDebugTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/60.0 target:self selector:@selector(simulatorUploadTexture) userInfo:nil repeats:YES];

#endif	

	capturing = YES;
}

- (void)stopCapture;
{
#if TARGET_OS_EMBEDDED
	[captureSession stopRunning];
	captureSession = nil;
	captureInput = nil;
	dataOutput = nil;
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

- (void)captureOutput:(AVCaptureOutput *)captureOutput  didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer 
	   fromConnection:(AVCaptureConnection *)connection;
{	
	
	dispatch_sync(dispatch_get_main_queue(), ^{
		if (capturing) {
			//Get buffer info
			CVPixelBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
			
#if 0
			NSDictionary *dict = (__bridge_transfer NSDictionary *)CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
			
			CMSampleTimingInfo timing;
			CMSampleBufferGetSampleTimingInfo(sampleBuffer, 0, &timing);
			
			NSLog(@"sample attachments: %@", dict);
#endif
			
			//NSLog(@"Is ready: %@ samples:%uld sampleSize:%d width:%d height:%d bytes/row:%d baseAddr:%x", ready ? @"Y" : @"N", numsamples, sampleSize, width, height, bytesPerRow, baseAddress);
			
			//Copy buffer contents into vram
			GL_CHECK_ERROR;
			//[textures[currentTexture] setData:baseAddress pixelFormat:kWMTexture2DPixelFormat_BGRA8888 pixelsWide:width pixelsHigh:height contentSize:(CGSize){width, height} orientation:currentVideoOrientation];
			
			//Create a BGRA texture
			
			WMCVTexture2D *texture = [[WMCVTexture2D alloc] initWithCVImageBuffer:imageBuffer inTextureCache:textureCache format:kWMTexture2DPixelFormat_BGRA8888];
			texture.orientation = currentVideoOrientation;
			
			GL_CHECK_ERROR;
			
			//TODO: Pass this texture back to main thread from bg thread.
			mostRecentTexture = texture;
			
			GL_CHECK_ERROR;
		}
	});
}
#else

- (void)simulatorUploadTexture;
{
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
}

#endif



- (WMTexture2D *)getVideoTexture;
{
	return mostRecentTexture;
}

- (BOOL)execute:(WMEAGLContext *)context time:(double)time arguments:(NSDictionary *)args;
{
	useFrontCamera = [[args objectForKey:@"com.darknoon.WMVideoCapture.useFront"] boolValue];
	
	UIInterfaceOrientation interfaceOrientation = [[args objectForKey:WMEngineArgumentsInterfaceOrientationKey] intValue];
	
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
	
	if (!capturing && inputCapture.value) {
		[self startCapture];
	}
	if (capturing && !inputCapture.value) {
		[self stopCapture];
	}
	
	outputImage.image = [self getVideoTexture];
	
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
