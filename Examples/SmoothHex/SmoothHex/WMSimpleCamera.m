//
//  WMSimpleCamera.m
//  SmoothHex
//
//  Created by Andrew Pouliot on 2/14/13.
//  Copyright (c) 2013 Darknoon. All rights reserved.
//

#import "WMSimpleCamera.h"

#import <WMLite/WMLite.h>
#import <AVFoundation/AVFoundation.h>

@interface WMSimpleCamera () <AVCaptureVideoDataOutputSampleBufferDelegate>

@end

@implementation WMSimpleCamera  {
	WMEAGLContext *_context;
	
	void (^_captureBlock)(WMTexture2D *texture);
			 
	dispatch_queue_t _targetQueue;
	
	dispatch_queue_t _videoCaptureQueue;
	AVCaptureSession *_captureSession;
	AVCaptureInput *_captureVideoInput;
	AVCaptureDevice *_cameraDevice;
	AVCaptureVideoDataOutput *_videoDataOutput;
	
	
	CVOpenGLESTextureCacheRef _textureCache;
}

- (id)initWithTargetQueue:(dispatch_queue_t)queue context:(WMEAGLContext *)context captureBlock:(void (^)(WMTexture2D *texture))block;
{
	self = [super init];
	if (!self) return nil;

	_targetQueue = queue;
	_videoCaptureQueue = dispatch_queue_create("com.darknoon.WMSimpleCamera.CaptureSerial", DISPATCH_QUEUE_SERIAL);
	//TODO: dispatch_set_target_queue(_videoCaptureQueue, _targetQueue);
	
	_captureBlock = [block copy];
	
	_context = context;
	
	dispatch_async(_videoCaptureQueue, ^{
		_captureSession = [[AVCaptureSession alloc] init];
		[_captureSession beginConfiguration];
		
		for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
			if (device.position == AVCaptureDevicePositionBack) {
				_cameraDevice = device;
			}
		}
		
		NSError *error;
		
		[_captureSession setSessionPreset:AVCaptureSessionPreset1920x1080];
		
		_captureVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:_cameraDevice error:&error];
		[_captureSession addInput:_captureVideoInput];

		_videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
		[_videoDataOutput setVideoSettings:@{ (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)}];
		[_videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
		[_videoDataOutput setSampleBufferDelegate:self queue:_videoCaptureQueue];
		[_captureSession addOutput:_videoDataOutput];

		CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, context, NULL, &_textureCache);
		NSAssert(_textureCache, @"couldn't create texture cache : %d", err);
		
		[_captureSession commitConfiguration];
		
	});
	
	return self;
}

- (void)beginCapture;
{
	dispatch_async(_videoCaptureQueue, ^{
		//Start capturing
		[_captureSession startRunning];
	});
}

- (void)stopCapture;
{
	dispatch_async(_videoCaptureQueue, ^{
		[_captureSession stopRunning];
	});
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection;
{
	[WMEAGLContext setCurrentContext:_context];
	
	WMCVTexture2D *texture = [[WMCVTexture2D alloc] initWithCVImageBuffer:CMSampleBufferGetImageBuffer(sampleBuffer) inTextureCache:_textureCache format:kWMTexture2DPixelFormat_BGRA8888 use:NSStringFromClass(self.class)];
	
	if (texture) {
		dispatch_sync(_targetQueue, ^{
			_captureBlock(texture);
			CVOpenGLESTextureCacheFlush(_textureCache, 0);
		});
	}
}

@end
