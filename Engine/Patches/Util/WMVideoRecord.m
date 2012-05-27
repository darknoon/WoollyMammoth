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

static CVPixelBufferPoolRef CreatePixelBufferPool( int32_t width, int32_t height, OSType pixelFormat);
static CVPixelBufferPoolRef CreatePixelBufferPool( int32_t width, int32_t height, OSType pixelFormat)
{
	CVPixelBufferPoolRef outputPool = NULL;
	
    CFMutableDictionaryRef sourcePixelBufferOptions = CFDictionaryCreateMutable( kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks );
    CFNumberRef number = CFNumberCreate( kCFAllocatorDefault, kCFNumberSInt32Type, &pixelFormat );
    CFDictionaryAddValue( sourcePixelBufferOptions, kCVPixelBufferPixelFormatTypeKey, number );
    CFRelease( number );
    
    number = CFNumberCreate( kCFAllocatorDefault, kCFNumberSInt32Type, &width );
    CFDictionaryAddValue( sourcePixelBufferOptions, kCVPixelBufferWidthKey, number );
    CFRelease( number );
    
    number = CFNumberCreate( kCFAllocatorDefault, kCFNumberSInt32Type, &height );
    CFDictionaryAddValue( sourcePixelBufferOptions, kCVPixelBufferHeightKey, number );
    CFRelease( number );
    
    CFDictionaryAddValue( sourcePixelBufferOptions, kCVPixelFormatOpenGLESCompatibility, kCFBooleanTrue );
    
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
	
//	BOOL                        _writing;
//	BOOL                        _importing;   	
	BOOL                        _writingDidStart;        
	AVAssetWriter               *_assetWriter;
	AVAssetWriterInput          *_assetWriterVideoInput;
}
@synthesize writing = _writing;
@synthesize savingToPhotos;

+ (void)load;
{
	@autoreleasepool {
		[self registerPatchClass];
	}
}

+ (id)defaultValueForInputPortKey:(NSString *)inKey;
{
	if ([inKey isEqualToString:@"inputWidth"]) {
		return [NSNumber numberWithUnsignedInt:1024];
	} else if ([inKey isEqualToString:@"inputHeight"]) {
		return [NSNumber numberWithUnsignedInt:768];
	}
	return [super defaultValueForInputPortKey:inKey];
}

- (void)removeFileURL:(NSURL *)fileURL
{
    NSString *outputPath = [fileURL path];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:outputPath]) {
        [fileManager removeItemAtPath:outputPath error:nil];
    }
}


- (BOOL)createVideoAssetWriter 
{
	BOOL succeeded = NO; 
	NSURL *fileURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"WMVideoRecord.mov"] isDirectory:NO];
	[self removeFileURL:fileURL];
	NSLog(@"fileURL %@", fileURL);
	NSError *error = nil;
	_assetWriter = [[AVAssetWriter alloc] initWithURL:fileURL fileType:@"com.apple.quicktime-movie"/*kUTTypeQuickTimeMovie*/ error:&error];
	if (error) {
		NSLog(@"Couldn't create AVAssetWriter (%@ %@)", error, [error userInfo]);
		goto bail;
	}

	{
		
		int bitsPerSecond = 1312500 * 8;
		if (videoDimensions.width <= 192 && videoDimensions.height <= 144)
			bitsPerSecond = 16000 * 8;
		else if (videoDimensions.width <= 480 && videoDimensions.height <= 360)
			bitsPerSecond = 87500 * 8;
		else if (videoDimensions.width <= 640 && videoDimensions.height <= 480)
			bitsPerSecond = 437500 * 8;
		
		NSDictionary *videoCompressionSettings = [NSDictionary dictionaryWithObjectsAndKeys:
												  AVVideoCodecH264, AVVideoCodecKey,
												  [NSNumber numberWithInteger:videoDimensions.width], AVVideoWidthKey,
												  [NSNumber numberWithInteger:videoDimensions.height], AVVideoHeightKey,
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
		if ([_assetWriter canAddInput:_assetWriterVideoInput])
			[_assetWriter addInput:_assetWriterVideoInput];
		else {
			NSLog(@"Couldn't add video asset writer input.");
			goto bail;
		}    
	}
	
	succeeded = YES; 
bail:
	if (!succeeded) {
		_assetWriter = nil;
		_assetWriterVideoInput = nil; 
	}
	return succeeded;
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

- (void)stopWriting 
{
    dispatch_sync(videoProcessingQueue, ^{
        if (self.writing) {   
            NSURL *fileURL = [_assetWriter outputURL];
            BOOL success = [_assetWriter finishWriting];
            NSLog(@"finishWriting %d", success);
            NSLog(@"fileURL %@", fileURL);
            if (success) {
                ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
                if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:fileURL]) {
					self.savingToPhotos = YES;
                    [library writeVideoAtPathToSavedPhotosAlbum:fileURL
                                                completionBlock:^(NSURL *assetURL, NSError *error){
                                                    if (error) {
                                                        NSLog(@"Error: %@ %@", error, [error userInfo]);
                                                    } 
                                                    else {
                                                        NSLog(@"Video saved to photos: %@", assetURL);
                                                    }
													self.savingToPhotos = NO;													 
                                                }];
                }
            }
            else {
                NSLog(@"finishWriting failed");
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
			
            [self removeFileURL:fileURL];
            
            _assetWriter = nil;
            _assetWriterVideoInput = nil;
            
            self.writing = NO; 
        }
    });
}


- (BOOL)appendBufferToAssetWriterInput:(CVImageBufferRef)pixelBuffer forTime:(CMTime)inTime
{
	BOOL success = NO;
	CMSampleBufferRef resultBuffer = NULL;
	CMFormatDescriptionRef formatDescription = NULL;    
	
	
	if (!_writingDidStart) {
		success = [_assetWriter startWriting];
		if (success) {
			[_assetWriter startSessionAtSourceTime:inTime];
			_writingDidStart = YES;
		}
		else {
			NSLog(@"appendVideoToAssetWriterInput, startWriting failed");
			goto bail;
		}
	}
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
	videoDimensions.width = 480;
	videoDimensions.height = 640;
	videoBufferPool = CreatePixelBufferPool(videoDimensions.width, videoDimensions.height, kCVPixelFormatType_32BGRA);
    if (!videoBufferPool) {
        NSLog(@"Couldn't create a pixel buffer pool.");
        return NO;
    }
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
	
	dispatch_release(videoProcessingQueue);
}


- (void)renderObject:(WMRenderObject *)inObject withTransform:(GLKMatrix4)inMatrix inContext:(WMEAGLContext *)inContext;
{
	[inObject postmultiplyTransform:inMatrix];
	[inContext renderObject:inObject];
}

- (BOOL)execute:(WMEAGLContext *)context time:(double)time arguments:(NSDictionary *)args;
{
	//TODO: If output dimensions change, cancel read and re-create
	
	BOOL shouldBeWriting = inputShouldRecord.value;
	
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
		
		//Invert y-axis
		transform = GLKMatrix4Scale(transform, 1.0f, -1.0f, 1.0f);
		
		if (inputRenderable1.object) {
			[self renderObject:inputRenderable1.object withTransform:transform inContext:context];
		}
		if (inputRenderable2.object) {
			[self renderObject:inputRenderable2.object withTransform:transform inContext:context];
		}
		if (inputRenderable3.object) {
			[self renderObject:inputRenderable3.object withTransform:transform inContext:context];
		}
		if (inputRenderable4.object) {
			[self renderObject:inputRenderable4.object withTransform:transform inContext:context];
		}

	}];
	
	glFinish();
	
	//Write out sample buffer
	
	if (shouldBeWriting) {
		[self appendBufferToAssetWriterInput:destPixelBuffer forTime:CMTimeMake(time * 1000000000, 1000000000)];
	}
	
	[framebuffer setColorAttachmentWithTexture:nil];
	
	currentTexture.orientation = UIImageOrientationUp;
	outputImage.image = currentTexture;
	
	CVOpenGLESTextureCacheFlush(textureCache, 0);
	CFRelease(destPixelBuffer);
		
	return YES;
	
}


@end
