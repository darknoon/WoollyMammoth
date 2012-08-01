//
//  WMCVTexture2D.h
//  WMEdit
//
//  Created by Andrew Pouliot on 8/13/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import "WMTexture2D.h"

#import <CoreVideo/CVOpenGLESTextureCache.h>

@interface WMCVTexture2D : WMTexture2D

- (id)initWithCVImageBuffer:(CVImageBufferRef)inImageBuffer inTextureCache:(CVOpenGLESTextureCacheRef)inTextureCache format:(WMTexture2DPixelFormat)inFormat use:(NSString *)useInfo;

@property (nonatomic) NSTimeInterval createTime;
@property (nonatomic, copy) NSString *use;

@end
