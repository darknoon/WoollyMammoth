//
//  WMVideoRecord.m
//  WMEdit
//
//  Created by Andrew Pouliot on 9/4/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import "WMVideoRecord.h"
#import <CoreVideo/CoreVideo.h>
#import <AVFoundation/AVFoundation.h>
#import "WMFramebuffer.h"
#import "WMCVTexture2D.h"
#import "WMEAGLContext.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "WMEngine.h"
#import "WMRenderObject.h"
#import "WMAudioBuffer.h"

static CVPixelBufferPoolRef CreatePixelBufferPool(int32_t width, int32_t height, OSType pixelFormat);
static CVPixelBufferPoolRef CreatePixelBufferPool(int32_t width, int32_t height, OSType pixelFormat)
{
	CVPixelBufferPoolRef outputPool = NULL;
	
	CFMutableDictionaryRef sourcePixelBufferOptions = CFDictionaryCreateMutable( kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
	
	CFDictionaryAddValue( sourcePixelBufferOptions, kCVPixelBufferPixelFormatTypeKey, (__bridge CFNumberRef)[NSNumber numberWithInt:pixelFormat]);
	
	CFDictionaryAddValue( sourcePixelBufferOptions, kCVPixelBufferWidthKey, (__bridge CFNumberRef)[NSNumber numberWithInt:width]);
	CFDictionaryAddValue( sourcePixelBufferOptions, kCVPixelBufferHeightKey, (__bridge CFNumberRef)[NSNumber numberWithInt:height]);
	CFDictionaryAddValue( sourcePixelBufferOptions, kCVPixelFormatOpenGLESCompatibility, kCFBooleanTrue);
	
	CFDictionaryRef ioSurfaceProps = CFDictionaryCreate( kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks );      
	if (ioSurfaceProps) {
		CFDictionaryAddValue( sourcePixelBufferOptions, kCVPixelBufferIOSurfacePropertiesKey, ioSurfaceProps );
		CFRelease(ioSurfaceProps);
	}
	
	CVPixelBufferPoolCreate( kCFAllocatorDefault, NULL, sourcePixelBufferOptions, &outputPool );
	
	CFRelease( sourcePixelBufferOptions );
	return outputPool;
}

@interface WMVideoRecord ()

@property (nonatomic, readwrite) BOOL writing;
@property (nonatomic, readwrite) BOOL savingToPhotos;

@end


@implementation WMVideoRecord {
	CVPixelBufferPoolRef videoBufferPool;
	CVOpenGLESTextureCacheRef textureCache;
	dispatch_queue_t videoProcessingQueue;
	
	//Render to the output texture with this FB
	WMFramebuffer *framebuffer;
	
	CMVideoDimensions videoDimensions;
	
	BOOL                        _writingDidStart;        
	AVAssetWriter               *_assetWriter;
	AVAssetWriterInput          *_assetWriterVideoInput;
	AVAssetWriterInput          *_assetWriterAudioInput;
}
@synthesize writing = _writing;
@synthesize savingToPhotos;
@synthesize inputRenderable1 = _inputRenderable1;
@synthesize inputRenderable2 = _inputRenderable2;
@synthesize inputRenderable3 = _inputRenderable3;
@synthesize inputRenderable4 = _inputRenderable4;
@synthesize inputShouldRecord = _inputShouldRecord;
@synthesize inputWidth = _inputWidth;
@synthesize inputHeight = _inputHeight;
@synthesize inputOrientation = _inputOrientation;
@synthesize inputAudio = _inputAudio;
@synthesize outputRecording = _outputRecording;
@synthesize outputSaving = _outputSaving;
@synthesize outputImage = _outputImage;


+ (void)load;
{
	@autoreleasepool {
		[self registerPatchClass];
	}
}

+ (id)defaultValueForInputPortKey:(NSString *)inKey;
{
	if ([inKey isEqualToString:@"inputWidth"]) {
		return [NSNumber numberWithUnsignedInt:640];
	} else if ([inKey isEqualToString:@"inputHeight"]) {
		return [NSNumber numberWithUnsignedInt:480];
	}
	return [super defaultValueForInputPortKey:inKey];
}

- (BOOL)createVideoAssetWriter 
{
	NSURL *fileURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"WMVideoRecord.mov"] isDirectory:NO];
	[[NSFileManager defaultManager] removeItemAtPath:fileURL.path error:nil];
	
	NSLog(@"fileURL %@", fileURL);
	NSError *error = nil;
	_assetWriter = [[AVAssetWriter alloc] initWithURL:fileURL fileType:@"com.apple.quicktime-movie"/*kUTTypeQuickTimeMovie*/ error:&error];
	if (error) {
		NSLog(@"Couldn't create AVAssetWriter (%@ %@)", error, [error userInfo]);
		goto bail;
	}
	
	//Video output setting / creation
	{
		
		//TODO: pick better encoding settings
		
		int bitsPerSecond = 1312500 * 8;
		if (videoDimensions.width <= 192 && videoDimensions.height <= 144)
			bitsPerSecond = 16000 * 8;
		else if (videoDimensions.width <= 480 && videoDimensions.height <= 360)
			bitsPerSecond = 87500 * 8;
		else if (videoDimensions.width <= 640 && videoDimensions.height <= 480)
			bitsPerSecond = 437500 * 8;
		
		NSDictionary *videoCompressionSettings = [NSDictionary dictionaryWithObjectsAndKeys:
												  AVVideoCodecH264, AVVideoCodecKey,
												  [NSNumber numberWithInt:videoDimensions.width], AVVideoWidthKey,
												  [NSNumber numberWithInt:videoDimensions.height], AVVideoHeightKey,
												  [NSDictionary dictionaryWithObjectsAndKeys:
												   [NSNumber numberWithInteger:bitsPerSecond], AVVideoAverageBitRateKey,
												   [NSNumber numberWithInteger:30], AVVideoMaxKeyFrameIntervalKey,
												   nil], AVVideoCompressionPropertiesKey,
												  nil];
		
		if ([_assetWriter canApplyOutputSettings:videoCompressionSettings forMediaType:AVMediaTypeVideo]) {
			_assetWriterVideoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoCompressionSettings];
			_assetWriterVideoInput.expectsMediaDataInRealTime = YES;
			// _assetWriterVideoInput.transform = [self assetWriterTransformForDeviceOrientation];
		}
		else {
			NSLog(@"Couldn't apply video output settings.");
			goto bail;
		}
		if ([_assetWriter canAddInput:_assetWriterVideoInput]) {
			[_assetWriter addInput:_assetWriterVideoInput];
		} else {
			NSLog(@"Couldn't add video asset writer input.");
			goto bail;
		}    
	}
	
	{
		double preferredHardwareSampleRate = [[AVAudioSession sharedInstance] currentHardwareSampleRate];
		
		AudioChannelLayout acl;
		bzero( &acl, sizeof(acl));
		acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
		
		NSDictionary *audioCompressionSettings = [NSDictionary dictionaryWithObjectsAndKeys:
												  [ NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
												  [ NSNumber numberWithInt: 1 ], AVNumberOfChannelsKey,
												  [ NSNumber numberWithFloat: preferredHardwareSampleRate ], AVSampleRateKey,
												  [ NSData dataWithBytes: &acl length: sizeof( acl ) ], AVChannelLayoutKey,
												  //[ NSNumber numberWithInt:AVAudioQualityLow], AVEncoderAudioQualityKey,
												  [ NSNumber numberWithInt: 64000 ], AVEncoderBitRateKey,
												  nil];

		_assetWriterAudioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:audioCompressionSettings];
		_assetWriterAudioInput.expectsMediaDataInRealTime = YES;
		if ([_assetWriter canAddInput:_assetWriterAudioInput]) {
			[_assetWriter addInput:_assetWriterAudioInput];
		} else {
			NSLog(@"Couldn't add audio asset writer input.");
			goto bail;
		}    

	}
	
	return YES;
	
bail:
	_assetWriter = nil;
	_assetWriterVideoInput = nil; 
	_assetWriterAudioInput = nil;
	return NO;
}

- (void)startWriting 
{
    dispatch_sync(videoProcessingQueue, ^{    
        if (!self.writing) {
            self.writing = [self createVideoAssetWriter];
			_writingDidStart = NO;
        }
    });
}

NSString *writerStatus(AVAssetWriterStatus status)
{
	switch (status) {
		default:
		case AVAssetWriterStatusUnknown:
			return @"unknown";
		case AVAssetWriterStatusWriting:
			return @"writing";
		case AVAssetWriterStatusCompleted:
			return @"completed";
		case AVAssetWriterStatusFailed:
			return @"failed";
		case AVAssetWriterStatusCancelled:
			return @"cancelled";
	}
}

- (void)stopWriting 
{
    dispatch_sync(videoProcessingQueue, ^{
        if (self.writing) {   
            NSURL *fileURL = [_assetWriter outputURL];

            DLog(@"before finishWriting status: %@", writerStatus(_assetWriter.status));
            
			BOOL success = [_assetWriter finishWriting];
			
			//TODO: dispatch_async to another queue and save to photos in the background?
            DLog(@"after finishWriting status: %@", writerStatus(_assetWriter.status));
			
            //DLog(@"fileURL %@", fileURL);
            if (success) {
                ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
                if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:fileURL]) {
					self.savingToPhotos = YES;
                    [library writeVideoAtPathToSavedPhotosAlbum:fileURL
                                                completionBlock:^(NSURL *assetURL, NSError *error){
                                                    if (error) {
                                                        DLog(@"Error: %@ %@", error, [error userInfo]);
                                                    } else {
                                                        DLog(@"Video saved to photos: %@", assetURL);
                                                    }
													self.savingToPhotos = NO;													 
                                                }];
                } else {
					DLog(@"Created a video not compatible with the photo library :(");
				}
            }
            else {
                DLog(@"finishWriting failed with error: %@", _assetWriter.error);
            }   
            
            _assetWriter = nil;
            _assetWriterVideoInput = nil;  
			self.writing = NO;
        }
    });
}

- (void)cancelWriting 
{     
    dispatch_sync(videoProcessingQueue, ^{
        if (self.writing) {             
            NSURL *fileURL = [_assetWriter outputURL];              
            [_assetWriter cancelWriting];
			
			[[NSFileManager defaultManager] removeItemAtPath:fileURL.path error:nil];
            
            _assetWriter = nil;
            _assetWriterVideoInput = nil;
			_assetWriterAudioInput = nil;
            
            self.writing = NO; 
        }
    });
}

- (BOOL)startSessionIfNeededAtTime:(CMTime)time;
{
	if (!_writingDidStart) {
		BOOL success = [_assetWriter startWriting];
		if (success) {
			[_assetWriter startSessionAtSourceTime:time];
			_writingDidStart = YES;
			return YES;
		} else {
			NSLog(@"startWriting failed");
			return NO;
		}
	} else {
		return YES;
	}
}

- (BOOL)appendAudioBufferToAssetWriterInput:(CMSampleBufferRef)audioBuffer forTime:(CMTime)inTime;
{
	BOOL success = [self startSessionIfNeededAtTime:inTime];
	
	if (_assetWriterAudioInput.readyForMoreMediaData) {       
		[_assetWriterAudioInput appendSampleBuffer:audioBuffer];
	} else {
		NSLog(@"Dropping audio");
	}
	return success;
}

- (BOOL)appendVideoBufferToAssetWriterInput:(CVImageBufferRef)pixelBuffer forTime:(CMTime)inTime;
{
	BOOL success = NO;
	CMSampleBufferRef resultBuffer = NULL;
	CMFormatDescriptionRef formatDescription = NULL;    
	
	if (_assetWriterVideoInput.readyForMoreMediaData) {       
		
		OSStatus status = CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer, &formatDescription);
		if (status) {
			NSLog(@"appendVideoToAssetWriterInput, CMVideoFormatDescriptionCreateForImageBuffer failure.");
			goto bail;           
		}
		
		CMSampleTimingInfo timingInfo = kCMTimingInfoInvalid;
		timingInfo.duration = (CMTime){};
		timingInfo.decodeTimeStamp = (CMTime){};
		timingInfo.presentationTimeStamp = inTime;
		
		status = CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault, pixelBuffer, TRUE, NULL, NULL, formatDescription, &timingInfo, &resultBuffer);
		if (status) {
			NSLog(@"appendVideoToAssetWriterInput, CMSampleBufferCreateForImageBuffer failure.");
			goto bail;           
		}    
		
		success = [_assetWriterVideoInput appendSampleBuffer:resultBuffer];
	}
	else {
		NSLog(@"appendVideoToAssetWriterInput, readyForMoreMediaData NO.");
		success = YES; // Not ready
	}
	
bail: 
	if (resultBuffer) {
		CFRelease(resultBuffer);
	}
	if (formatDescription) {
		CFRelease(formatDescription);
	}
	return success;
}


- (BOOL)setup:(WMEAGLContext *)context;
{	
	CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, (__bridge void *)context, NULL, &textureCache);
	if (err != kCVReturnSuccess) {
		NSLog(@"Couldn't create texture cache for writing video file");
        return NO;
	}
	
	//TODO: rename this
	videoProcessingQueue = dispatch_queue_create("com.darknoon.writevideo", DISPATCH_QUEUE_SERIAL);
	if (!videoProcessingQueue) {
		NSLog(@"Couldn't create the queue to perform video output processing on");
		return NO;
	}
	
	return YES;
}

- (void)cleanup:(WMEAGLContext *)context;
{
	CVPixelBufferPoolRelease(videoBufferPool);
	videoBufferPool = NULL;

	if (textureCache) CFRelease(textureCache);
	
	if (videoProcessingQueue) {
		dispatch_release(videoProcessingQueue);
		videoProcessingQueue = NULL;
	}
}


- (void)renderObject:(WMRenderObject *)inObject withTransform:(GLKMatrix4)inMatrix inContext:(WMEAGLContext *)inContext;
{
	[inObject postmultiplyTransform:inMatrix];
	[inContext renderObject:inObject];
}

- (BOOL)recreatePixelBufferPool;
{
	if (videoBufferPool) {
		CVPixelBufferPoolRelease(videoBufferPool);
		videoBufferPool = NULL;
	}
	
	NSLog(@"recreating pixel buffer pool width:%d height:%d", videoDimensions.width, videoDimensions.height);
	
	videoBufferPool = CreatePixelBufferPool(videoDimensions.width, videoDimensions.height, kCVPixelFormatType_32BGRA);
	if (!videoBufferPool) {
		NSLog(@"Couldn't create a pixel buffer pool.");
		return NO;
	}
	return YES;
}

- (BOOL)execute:(WMEAGLContext *)context time:(double)time arguments:(NSDictionary *)args;
{
	
	//Use output dimensions from last time we weren't writing
	
	BOOL shouldBeWriting = _inputShouldRecord.value;
	
	if (!self.writing) {
		
		//If dimensions changed, recreate video buffer pool
		if (videoDimensions.width != _inputWidth.index || videoDimensions.height != _inputHeight.index) {
			videoDimensions.width  = _inputWidth.index;
			videoDimensions.height = _inputHeight.index;

			[self recreatePixelBufferPool];
		}
	}
	
	if (shouldBeWriting && !self.writing && !self.savingToPhotos) {
		NSLog(@"Attempting to create asset writer.");
		[self startWriting];
	} else if (!shouldBeWriting && self.writing) {
		[self stopWriting];
	}
	
	
	CVPixelBufferRef destPixelBuffer = NULL;
	CVReturn err = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, videoBufferPool, &destPixelBuffer);
    if (!destPixelBuffer || err != kCVReturnSuccess) {
        NSLog(@"displayAndRenderPixelBuffer error");
		return NO;
    }
	
	WMCVTexture2D *currentTexture = [[WMCVTexture2D alloc] initWithCVImageBuffer:destPixelBuffer inTextureCache:textureCache format:kWMTexture2DPixelFormat_BGRA8888];
	
	if (!framebuffer /* || framebuffer parameters are not consistent with inputs... */) {
		framebuffer = [[WMFramebuffer alloc] initWithTexture:currentTexture depthBufferDepth:0];		
	} else {
		[framebuffer setColorAttachmentWithTexture:currentTexture];
	}
	

	[context renderToFramebuffer:framebuffer block:^{
				
		[context clearToColor:(GLKVector4){0, 0, 0, 1}];
		[context clearDepth];
		
		if (!currentTexture || err) {
			NSLog(@"displayAndRenderPixelBuffer error"); 
		}
		
		GLKMatrix4 transform = [WMEngine cameraMatrixWithRect:(CGRect){.size.width = videoDimensions.width, .size.height = videoDimensions.height}];
		
		
		switch (_inputOrientation.index) {
			default:
			case UIImageOrientationUp:
				break;
			case UIImageOrientationUpMirrored:
				//Flip x
				transform = GLKMatrix4Scale(transform, -1.0f, 1.0f, 1.0f);
				break;
			case UIImageOrientationDown:
				transform = GLKMatrix4Scale(transform, -1.0f, -1.0f, 1.0f);
				break;
			case UIImageOrientationDownMirrored:
				transform = GLKMatrix4Scale(transform, 1.0f, -1.0f, 1.0f);
				break;
			case UIImageOrientationLeft:
				//Rotate 90° ccw
				transform = GLKMatrix4RotateZ(transform, -M_PI_2);
				break;
			case UIImageOrientationLeftMirrored:
				transform = GLKMatrix4RotateZ(transform, -M_PI_2);
				transform = GLKMatrix4Scale(transform, -1.0f, 1.0f, 1.0f);
				break;
			case UIImageOrientationRight:
				transform = GLKMatrix4RotateZ(transform, M_PI_2);
				break;
			case UIImageOrientationRightMirrored:
				transform = GLKMatrix4RotateZ(transform, M_PI_2);
				transform = GLKMatrix4Scale(transform, -1.0f, 1.0f, 1.0f);
				break;
		}

		//Invert y-axis to account for different GL/CV coordinates
		transform = GLKMatrix4Scale(transform, 1.0f, -1.0f, 1.0f);

		
		if (_inputRenderable1.object) {
			[self renderObject:_inputRenderable1.object withTransform:transform inContext:context];
		}
		if (_inputRenderable2.object) {
			[self renderObject:_inputRenderable2.object withTransform:transform inContext:context];
		}
		if (_inputRenderable3.object) {
			[self renderObject:_inputRenderable3.object withTransform:transform inContext:context];
		}
		if (_inputRenderable4.object) {
			[self renderObject:_inputRenderable4.object withTransform:transform inContext:context];
		}

	}];
	
	glFinish();
	
	//Write out sample buffer
	
	if (shouldBeWriting) {
		CMTime timeStamp = kCMTimeInvalid;
		
		if (_inputAudio.objectValue) {
			WMAudioBuffer *firstAudioBuffer = (WMAudioBuffer *)_inputAudio.objectValue;
			CMSampleBufferRef sampleBuffer = (__bridge CMSampleBufferRef)[firstAudioBuffer.sampleBuffers objectAtIndex:0];
			timeStamp = CMSampleBufferGetPresentationTimeStamp( sampleBuffer );
		}
		
		dispatch_sync(videoProcessingQueue, ^{
			
			if (!CMTIME_IS_VALID(timeStamp)) return;
			
			BOOL success = [self startSessionIfNeededAtTime:timeStamp];
			
#if 0
			//A bug was causing audio packets to be written twiec
			NSMutableString *audioPacketPtrList = [[NSMutableString alloc] init];
			if (inputAudio.objectValue) {
				for (id sampleBuffer in ((WMAudioBuffer *)inputAudio.objectValue).sampleBuffers) {
					[audioPacketPtrList appendFormat:@"%p, ", sampleBuffer];
				}
			}
			DLog(@"assetWriter: %@ time:%lf.3 valid:%d audioPackets:%@", writerStatus(_assetWriter.status), CMTimeGetSeconds(timeStamp), CMTIME_IS_VALID(timeStamp), audioPacketPtrList);
#endif
			

			if (success && CMTIME_IS_VALID(timeStamp)) {
				
				[self appendVideoBufferToAssetWriterInput:destPixelBuffer forTime:timeStamp];
				
				if (_inputAudio.objectValue) {
					for (id sampleBuffer in ((WMAudioBuffer *)_inputAudio.objectValue).sampleBuffers) {
						CMSampleBufferRef sbref = (__bridge CMSampleBufferRef)sampleBuffer;
						[self appendAudioBufferToAssetWriterInput:sbref forTime:CMSampleBufferGetOutputPresentationTimeStamp(sbref)];
					}
				}
			}

		});
		
		
	}
	
	[framebuffer setColorAttachmentWithTexture:nil];
	
	currentTexture.orientation = _inputOrientation.index;
	_outputImage.image = currentTexture;
	
	CVOpenGLESTextureCacheFlush(textureCache, 0);
	CFRelease(destPixelBuffer);
		
	return YES;
	
}


@end
