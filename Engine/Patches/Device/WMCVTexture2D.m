//
//  WMCVTexture2D.m
//  WMEdit
//
//  Created by Andrew Pouliot on 8/13/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import "WMCVTexture2D.h"
#import "WMEAGLContext.h"
#import "WMTexture2D_WMEAGLContext_Private.h"
#import "WMTexture2D_RenderPrivate.h"

#define TRACK_ALL_CVTEXTURES 0

@implementation WMCVTexture2D {
	CVOpenGLESTextureRef cvTexture;
	CVImageBufferRef _imageBuffer;
}

#if TRACK_ALL_CVTEXTURES

static int textureCount;
/*
 Guys who retain the texture:
 
 WMRenderObject
 WMVideoRecord
 
 */
static NSMutableDictionary *textureUsesCounts;

- (void)incrementTextureCount;
{
	
	@synchronized (WMCVTexture2D.class) {
		if (!textureUsesCounts) {
			textureUsesCounts = [[NSMutableDictionary alloc] init];
		}
		int countForThisUse = [[textureUsesCounts objectForKey:self.use] intValue];
		[textureUsesCounts setObject:@(countForThisUse + 1) forKey:self.use];
		
		textureCount++;
		ZAssert(textureCount < 10, @"Too many CV textures outstanding: %d!", textureCount);
		
	}
}

- (void)decrementTextureCount;
{
	@synchronized(WMCVTexture2D.class) {
		int countForThisUse = [[textureUsesCounts objectForKey:self.use] intValue];
		[textureUsesCounts setObject:@(countForThisUse - 1) forKey:self.use];
		
		textureCount--;
	}
}

#endif

- (id)initWithCVImageBuffer:(CVImageBufferRef)inImageBuffer inTextureCache:(CVOpenGLESTextureCacheRef)inTextureCache format:(WMTexture2DPixelFormat)inFormat use:(NSString *)useInfo;
{
	self = [super init];
	if (!self) return nil;
	if (!inImageBuffer) return nil;
	if (!inTextureCache) return nil;
	
	self.use = useInfo;
	
#if TRACK_ALL_CVTEXTURES
	[self incrementTextureCount];
#endif
	
	CFDictionaryRef textureAttributes = NULL;
	
	ZAssert(inFormat == kWMTexture2DPixelFormat_BGRA8888, @"Other CV Texture formats currently unimplemented.");
	
	_imageBuffer = inImageBuffer;
	CFRetain(_imageBuffer);
	
	//Get width and height
	CGSize size = CVImageBufferGetEncodedSize(inImageBuffer);
	
	CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, inTextureCache, inImageBuffer, textureAttributes, GL_TEXTURE_2D, GL_RGBA, size.width, size.height, GL_BGRA, GL_UNSIGNED_BYTE, 0, &cvTexture);
	
	if (err == 0) {
		ZAssert(cvTexture, @"Texture null");
		ZAssert(CVOpenGLESTextureGetName(cvTexture) != 0, @"Texture has 0 name!");
		ZAssert(CVOpenGLESTextureGetTarget(cvTexture) == GL_TEXTURE_2D, @"Got a rect texture :(");

		GLKVector2 lowerLeft;
		GLKVector2 lowerRight;
		GLKVector2 upperLeft;
		GLKVector2 upperRight;
		
		CVOpenGLESTextureGetCleanTexCoords(cvTexture, lowerLeft.v, lowerRight.v, upperRight.v, upperLeft.v);
		
		ZAssert(fabsf(lowerRight.x - lowerLeft.x) > 0.1f && fabsf(upperLeft.y - lowerLeft.y) > 0.1f, @"Unexpected texture coordinate rotation!");
		
		_width = CVPixelBufferGetWidth(inImageBuffer);
		_height = CVPixelBufferGetHeight(inImageBuffer);

		_size.width = fabsf(lowerRight.x - lowerLeft.x) * _width;
		_size.height = fabsf(upperLeft.y - lowerLeft.y) * _height;
		
		//TODO: is this actually necessary?
		[self.context bind2DTextureNameForModification:CVOpenGLESTextureGetName(cvTexture) inBlock:^{
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
			glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		}];
	} else {
		NSLog(@"couldn't create gl texture! %d", err);
		return nil;
	}
	
	return self;
}

- (GLuint)name;
{
	return CVOpenGLESTextureGetName(cvTexture);	
}

- (void)setData:(const void*)data pixelFormat:(WMTexture2DPixelFormat)pixelFormat pixelsWide:(NSUInteger)width pixelsHigh:(NSUInteger)height contentSize:(CGSize)size orientation:(UIImageOrientation)inOrientation;
{
	//No-op
	ZAssert(0, @"Should not call -setData:… on WMCVTexture2D. The whole point of WMCVTexture2D is not to use pointers to data on the CPU!");
}

- (void)deleteInternalState;
{
	//CVOpenGLESTextureCache is responsible for deleting the texture, so just forget about it here
	//instead of super's implementation, which would actually delete the texture
	_name = 0;
}

- (void)dealloc;
{
#if TRACK_ALL_CVTEXTURES
	[self decrementTextureCount];
#endif
	//Even if our context has gone away, presumably we should still free the cvTexture...
	if (cvTexture)
		CFRelease(cvTexture);
	cvTexture = NULL;
	if (_imageBuffer) {
		CFRelease(_imageBuffer);
	}
}

@end
