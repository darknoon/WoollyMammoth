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

@implementation WMCVTexture2D {
	CVOpenGLESTextureRef cvTexture;
}

- (id)initWithCVImageBuffer:(CVImageBufferRef)inImageBuffer inTextureCache:(CVOpenGLESTextureCacheRef)inTextureCache format:(WMTexture2DPixelFormat)inFormat;
{
	self = [super init];
	if (!self) return nil;
	
	CFDictionaryRef textureAttributes = NULL;
	
	//Get width and height
	CGSize size = CVImageBufferGetEncodedSize(inImageBuffer);
		
	CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, inTextureCache, inImageBuffer, textureAttributes, GL_TEXTURE_2D, GL_RGBA, size.width, size.height, GL_BGRA, GL_UNSIGNED_BYTE, 0, &cvTexture);
	
	if (err == 0) {
		ZAssert(cvTexture, @"Texture null");
		ZAssert(CVOpenGLESTextureGetName(cvTexture) != 0, @"Texture has 0 name!");

		GLKVector2 lowerLeft;
		GLKVector2 lowerRight;
		GLKVector2 upperLeft;
		GLKVector2 upperRight;
		
		CVOpenGLESTextureGetCleanTexCoords(cvTexture, lowerLeft.v, lowerRight.v, upperRight.v, upperLeft.v);
		
		_size.width = fabsf(lowerRight.x - lowerLeft.x);
		_size.height = fabsf(upperLeft.y - lowerLeft.y);
		
		_width = CVPixelBufferGetWidth(inImageBuffer);
		_height = CVPixelBufferGetHeight(inImageBuffer);
		
		
		glBindTexture(GL_TEXTURE_2D, CVOpenGLESTextureGetName(cvTexture));

		[(WMEAGLContext *)[WMEAGLContext currentContext] bind2DTextureNameForModification:CVOpenGLESTextureGetName(cvTexture)]; 
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		
	} else {
		NSLog(@"couldn't create gl texture!");
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

- (void)dealloc;
{
	//Don't delete the texture name
	_name = 0;
	CFRelease(cvTexture);
}

@end
