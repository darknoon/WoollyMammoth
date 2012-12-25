//
//  WMCVTexture2D.h
//  WMEdit
//
//  Created by Andrew Pouliot on 8/13/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import "WMTexture2D.h"

#if TARGET_OS_IPHONE

#import <CoreVideo/CVOpenGLESTextureCache.h>
#define CVOGLTexCacheRef_t CVOpenGLESTextureCacheRef
#define CVOGLTexRef_t CVOpenGLESTextureRef

#elif TARGET_OS_MAC

#import <CoreVideo/CVOpenGLTextureCache.h>
#define CVOGLTexCacheRef_t CVOpenGLTextureCacheRef
#define CVOGLTexRef_t CVOpenGLTextureRef

#endif

@interface WMCVTexture2D : WMTexture2D

- (id)initWithCVImageBuffer:(CVImageBufferRef)inImageBuffer inTextureCache:(CVOGLTexCacheRef_t)inTextureCache format:(WMTexture2DPixelFormat)inFormat use:(NSString *)useInfo;

@property (nonatomic) NSTimeInterval createTime;
@property (nonatomic, copy) NSString *use;

@end
