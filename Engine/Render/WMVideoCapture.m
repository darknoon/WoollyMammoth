//
//  VideoCapture.m
//  CaptureTest
//
//  Created by Andrew Pouliot on 8/12/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "WMVideoCapture.h"

#import <CoreVideo/CoreVideo.h>

#import "WMEAGLContext.h"
#import "WMTexture2D.h"

#import "WMBooleanPort.h"
#import "WMImagePort.h"

@implementation WMVideoCapture

@synthesize capturing;

+ (void)load;
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self registerToRepresentClassNames:[NSSet setWithObject:@"QCVideoInput"]];
	[pool drain];
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

- (WMPatchExecutionMode)executionMode;
{
	return kWMPatchExecutionModeProvider;
}

- (void)dealloc
{
	[super dealloc];
}

+ (NSString *)category;
{
    return WMPatchCategoryInput;
}

- (BOOL)setup:(WMEAGLContext *)context;
{	
	GL_CHECK_ERROR;
	
	//TODO: why does this fail on ES2?
	if (context.API == kEAGLRenderingAPIOpenGLES1) {
		glEnable(GL_TEXTURE_2D);
	}

	GL_CHECK_ERROR;
	
	
	//TODO: get these from the camera session somehow
#if USE_LOW_RES_CAMERA
	unsigned width = 192;
	unsigned height = 144;
#else
	unsigned width = 640;
	unsigned height = 480;
#endif
	
	//Initialize the buffer
	unsigned char *buffer = malloc(4 * width * height);
	for (int y=0, i=0; y<height; y++) {
		for (int x=0; x<width; x++, i++) {
			//Set to medium grey for kicks
			buffer[4*i + 0] = 51;
			buffer[4*i + 1] = 51;
			buffer[4*i + 2] = 51;
			buffer[4*i + 3] = 255;
		}
	}

	//glTexParameterf(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_FALSE);

	for (int i=0; i<VideoCapture_NumTextures; i++) {
		textures[i] = [[WMTexture2D alloc] initWithData:buffer pixelFormat:kWMTexture2DPixelFormat_BGRA8888 pixelsWide:0 pixelsHigh:0 contentSize:CGSizeZero];
		glBindTexture(GL_TEXTURE_2D, [textures[i] name]);
		
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

#if USE_BGRA
		[textures[i] setData:buffer pixelFormat:kWMTexture2DPixelFormat_BGRA8888 pixelsWide:width pixelsHigh:height contentSize:(CGSize){width, height}];
//		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_BGRA_EXT, GL_UNSIGNED_BYTE, buffer);
#else
		[textures[i] setData:buffer pixelFormat:kWMTexture2DPixelFormat_RGBA8888 pixelsWide:width pixelsHigh:height contentSize:(CGSize){width, height}];
//		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA8_OES, GL_UNSIGNED_BYTE, buffer);
#endif
		GL_CHECK_ERROR;
	}
	glBindTexture(GL_TEXTURE_2D, 0);	
	
	
	free(buffer);
	return YES;
}

- (void)cleanup:(WMEAGLContext *)context;
{
	for (int i=0; i<VideoCapture_NumTextures; i++) {
		[textures[i] release];
	}
	[super cleanup:context];
}


- (void)startCapture;
{
	//TODO: make this hack less hacky
	if (capturing) return;
	
	ZAssert(textures[0] != 0, @"Tried to start capture without any textures!");
	
#if TARGET_OS_EMBEDDED
	captureSession = [[AVCaptureSession alloc] init];

#if USE_LOW_RES_CAMERA
	[captureSession setSessionPreset:AVCaptureSessionPresetLow];
#else
	[captureSession setSessionPreset:AVCaptureSessionPreset640x480];
#endif	
	NSError *error = nil;
	
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	DLog(@"Devices: %@", devices);
	
	//Look for back camera
	for (AVCaptureDevice *device in devices) {
		if (device.position == (useFrontCamera ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack)) {
			DLog(@"Video capture from device: %@", device);
			cameraDevice = [device retain];
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
	[dataOutput setMinFrameDuration:CMTimeMake(1, 60)];

	[dataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
	
	[captureSession addInput:captureInput];
	[captureSession addOutput:dataOutput];
	[captureSession startRunning];
#endif	
	capturing = YES;
}

- (void)stopCapture;
{
#if TARGET_OS_EMBEDDED
	[captureSession stopRunning];
	[captureSession release]; captureSession = nil;
	[captureInput release]; captureInput = nil;
#endif
	
	capturing = NO;
}

#if TARGET_OS_EMBEDDED

//On main thread, for texture upload :(
- (void)captureOutput:(AVCaptureOutput *)captureOutput 
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer 
	   fromConnection:(AVCaptureConnection *)connection;
{
	
#if DEBUG_TEXTURE_UPLOAD
	NSTimeInterval __START_TIME = CFAbsoluteTimeGetCurrent();
#endif

	if (!textureWasRead) {
		//NSLog(@"Texture was not read before swap!");
		return;
	}
	//Advance the current texture
	currentTexture = (currentTexture+1) % VideoCapture_NumTextures;
	textureWasRead = NO;

//Get the texture ready

	//Get buffer info
	CVPixelBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	CVPixelBufferLockBaseAddress(imageBuffer,0);
	uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
	//size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
	size_t width = CVPixelBufferGetWidth(imageBuffer);
	size_t height = CVPixelBufferGetHeight(imageBuffer);
	
	//NSLog(@"Is ready: %@ samples:%uld sampleSize:%d width:%d height:%d bytes/row:%d baseAddr:%x", ready ? @"Y" : @"N", numsamples, sampleSize, width, height, bytesPerRow, baseAddress);

	//Copy buffer contents into vram
	GL_CHECK_ERROR;
	//glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, width, height, GL_BGRA, GL_UNSIGNED_BYTE, baseAddress);
	[textures[currentTexture] setData:baseAddress pixelFormat:kWMTexture2DPixelFormat_BGRA8888 pixelsWide:width pixelsHigh:height contentSize:(CGSize){width, height}];
	//glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_BGRA_EXT, GL_UNSIGNED_BYTE, baseAddress);
	GL_CHECK_ERROR;
	
	//Now release the lock
	CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
	
#if DEBUG_TEXTURE_UPLOAD
	NSTimeInterval __END_TIME = CFAbsoluteTimeGetCurrent();
	
	NSTimeInterval mstime = (__END_TIME - __START_TIME) * 1000.0;
	
	//'W' if greater that 10 ms 'w' if less to upload texture
	log[logi++] = mstime > 10.0 ? 'W' : 'w';
	log[logi++] = '0' + (char)currentTexture;

	static int i=0;
	if (i%10 == 0) {
		log[logi] = '\0';
		logi = 0;
		NSLog(@"Texture upload time: %.3lf ms %s", mstime, log);
	}
	i = (i+1 % 10);
#endif //DEBUG_TEXTURE_UPLOAD
}
#else

- (void)simulatorUploadTexture;
{
	//Advance the current texture
	currentTexture = (currentTexture+1) % VideoCapture_NumTextures;
	//Get the texture ready
	glBindTexture(GL_TEXTURE_2D, [textures[currentTexture] name]);
	
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
	
	glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, width, height, GL_BGRA_EXT, GL_UNSIGNED_BYTE, buffer);
	
	free(buffer);
	
	glBindTexture(GL_TEXTURE_2D, 0);

}

#endif



- (WMTexture2D *)getVideoTexture;
{
	int textureToRead = (currentTexture - 1 + VideoCapture_NumTextures) % VideoCapture_NumTextures;
	textureWasRead = YES;
#if DEBUG_TEXTURE_UPLOAD
	log[logi++] = 'r';
	log[logi++] = '0' + (char)textureToRead;
#endif
#if TARGET_IPHONE_SIMULATOR
	[self simulatorUploadTexture];
#endif
	return textures[textureToRead];
}

- (BOOL)execute:(WMEAGLContext *)context time:(double)time arguments:(NSDictionary *)args;
{
	useFrontCamera = [[args objectForKey:@"com.darknoon.WMVideoCapture.useFront"] boolValue];
	
	if (!capturing && inputCapture.value) {
		[self startCapture];
	}
	if (capturing && !inputCapture.value) {
		[self stopCapture];
	}
	
	outputImage.image = [self getVideoTexture];
	
	return YES;
}

- (UIColor *)editorColor;
{
	return [UIColor colorWithRed:0.798f green:0.349f blue:0.061f alpha:0.8f];
}

@end
