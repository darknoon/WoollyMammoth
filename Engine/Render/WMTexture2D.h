/*

File: WMTexture2D.h
Abstract: Creates OpenGL 2D textures from images or text.

Version: 1.7

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc.
("Apple") in consideration of your agreement to the following terms, and your
use, installation, modification or redistribution of this Apple software
constitutes acceptance of these terms.  If you do not agree with these terms,
please do not use, install, modify or redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and subject
to these terms, Apple grants you a personal, non-exclusive license, under
Apple's copyrights in this original Apple software (the "Apple Software"), to
use, reproduce, modify and redistribute the Apple Software, with or without
modifications, in source and/or binary forms; provided that if you redistribute
the Apple Software in its entirety and without modifications, you must retain
this notice and the following text and disclaimers in all such redistributions
of the Apple Software.
Neither the name, trademarks, service marks or logos of Apple Inc. may be used
to endorse or promote products derived from the Apple Software without specific
prior written permission from Apple.  Except as expressly stated in this notice,
no other rights or licenses, express or implied, are granted by Apple herein,
including but not limited to any patent rights that may be infringed by your
derivative works or by other works in which the Apple Software may be
incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR
DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF
CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF
APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

Copyright (C) 2008 Apple Inc. All Rights Reserved.

*/

#import <Foundation/Foundation.h>
#import "WMRenderCommon.h"

#if !TARGET_OS_IPHONE
#import "WMCompatibilityMac.h"
#endif

#import "WMGLStateObject.h"

//CONSTANTS:

typedef enum {
	kWMTexture2DPixelFormat_Automatic = 0,
	kWMTexture2DPixelFormat_RGBA8888,
	kWMTexture2DPixelFormat_BGRA8888,
	kWMTexture2DPixelFormat_RGB565,
	kWMTexture2DPixelFormat_A8,
#if GL_EXT_texture_rg || GL_ARB_texture_rg
	kWMTexture2DPixelFormat_R8,
#endif
	//TODO: kWMTexture2DPixelFormat_RGB422
	//TODO: kWMTexture2DPixelFormat_RGBA16F
	//TODO: kWMTexture2DPixelFormat_RGBA32F
	//TODO: kWMTexture2DPixelFormat_R32F
	_WMTexture2DPixelFormat_count
} WMTexture2DPixelFormat;

/*
This class allows to easily create OpenGL 2D textures from images, text or raw data.
Depending on how you create the WMTexture2D object, the actual image area of the texture might be smaller than the texture dimensions i.e. "contentSize" != (pixelsWide, pixelsHigh) and (maxS, maxT) != (1.0, 1.0).
Be aware that the content of the generated textures will be upside-down!
*/
@interface WMTexture2D : WMGLStateObject

//Designated initializer
- (id)initWithData:(const void*)data pixelFormat:(WMTexture2DPixelFormat)pixelFormat pixelsWide:(GLuint)width pixelsHigh:(GLuint)height contentSize:(CGSize)size orientation:(UIImageOrientation)inOrientation;

- (id)initWithData:(const void*)data pixelFormat:(WMTexture2DPixelFormat)pixelFormat pixelsWide:(GLuint)width pixelsHigh:(GLuint)height contentSize:(CGSize)size;

//Experimental method that creates a fixed-size texture. You cannot modify the size later with -setData
//Only 1 mip level currently
- (id)initEmptyTextureWithPixelFormat:(WMTexture2DPixelFormat)pixelFormat width:(GLuint)width height:(GLuint)height;

//Indicates that the width or height of the texture may not be modified by one of the -setData APIs
@property (nonatomic, readonly) BOOL immutable;

//Resize the texture to the provided size and upload new data to it
- (void)setData:(const void*)data pixelFormat:(WMTexture2DPixelFormat)pixelFormat pixelsWide:(GLuint)width pixelsHigh:(GLuint)height contentSize:(CGSize)size;
- (void)setData:(const void*)data pixelFormat:(WMTexture2DPixelFormat)pixelFormat pixelsWide:(GLuint)width pixelsHigh:(GLuint)height contentSize:(CGSize)size orientation:(UIImageOrientation)inOrientation;

//Get a texture in the current context from another context's texture (changes the current texture, as you need to keep the texture name alive)
- (void)moveToContext:(WMEAGLContext *)inContext;

//Equivalent to binding the texture and glTexImage2D with NULL data
- (void)discardData;

//This is just metadata that's used by WMQuad and possibly other patches to determine how to interpret the image
@property (nonatomic) UIImageOrientation orientation;

@property (nonatomic, readonly) WMTexture2DPixelFormat pixelFormat;
@property (nonatomic, readonly) GLuint pixelsWide;
@property (nonatomic, readonly) GLuint pixelsHigh;

@property (nonatomic, readonly) CGSize contentSize;
@property (nonatomic, readonly) GLfloat maxS;
@property (nonatomic, readonly) GLfloat maxT;
@end

@interface WMTexture2D (File)
- (id)initWithContentsOfFile:(NSString *)inFilePath;
@end

@interface WMTexture2D (CGBitmapContext)
//For now, this is restricted to kWMTexture2DPixelFormat_BGRA8888
//Use this to draw arbitrary CPU graphics into a texture
- (id)initWithBitmapSize:(CGSize)size block:(void(^)(CGContextRef ctx))block;

- (id)initWithBitmapSize:(CGSize)size format:(WMTexture2DPixelFormat)format block:(void(^)(CGContextRef ctx))block;

@end


/*
Extensions to make it easy to create a WMTexture2D object from an image file.
Note that RGBA type textures will have their alpha premultiplied - use the blending mode (GL_ONE, GL_ONE_MINUS_SRC_ALPHA).
*/
@interface WMTexture2D (Image)
#if TARGET_OS_IPHONE
- (id)initWithImage:(UIImage *)uiImage;
- (id)initWithImage:(UIImage *)uiImage scale:(CGFloat)inScale;
#endif
- (id)initWithCGImage:(CGImageRef)image scale:(CGFloat)inScale orientation:(UIImageOrientation)inOrientation;
@end

#if TARGET_OS_IPHONE
/*
Extensions to make it easy to create a WMTexture2D object from a string of text.
Note that the generated textures are of type A8 - use the blending mode (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA).
*/
@interface WMTexture2D (Text)
- (id)initWithString:(NSString*)string dimensions:(CGSize)dimensions alignment:(UITextAlignment)alignment fontName:(NSString*)name fontSize:(CGFloat)size;
@end

#endif
