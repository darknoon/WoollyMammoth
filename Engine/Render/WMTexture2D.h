/**

 File: WMTexture2D.h
 Abstract: Creates OpenGL 2D textures from images or text.
*/

#import <Foundation/Foundation.h>
#import "WMRenderCommon.h"

#if !TARGET_OS_IPHONE
#import "WMCompatibilityMac.h"
#endif

#import "WMGLStateObject.h"

/**
 Pixel formats
 */
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

/**
 @abstract Represents an OpenGL texture.
 @discussion WMTexture2D provides methods to create textures from images, text, raw data, and CoreGraphics routines.
 
 Depending on how you create the WMTexture2D object, the actual image area of the texture might be smaller than the texture dimensions i.e. "contentSize" != (pixelsWide, pixelsHigh) and (maxS, maxT) != (1.0, 1.0).
 Be aware that the content of the generated textures will be upside-down!
 
 This is focused on textures with a single mip-level. Please file a bug if you are doing mip-mapping!
 
 Roughly based off of the now-defunct Texture2D sample code from Apple, but including a great many additions and changes.
 */
@interface WMTexture2D : WMGLStateObject

/** 
 @abstract Create a new texture with raw data
 @param data A pointer to image data in the correct pixel format, or NULL. If NULL, allocate a backing of the provided size with no content.
 @param pixelFormat What pixel format the texture should have
 @param width The new width of the texture
 @param height The new height of the texture
 @param orientation The new orientation of the texture
 */
- (id)initWithData:(const void*)data pixelFormat:(WMTexture2DPixelFormat)pixelFormat pixelsWide:(GLuint)width pixelsHigh:(GLuint)height contentSize:(CGSize)size orientation:(UIImageOrientation)inOrientation;

- (id)initWithData:(const void*)data pixelFormat:(WMTexture2DPixelFormat)pixelFormat pixelsWide:(GLuint)width pixelsHigh:(GLuint)height contentSize:(CGSize)size;

//
//Only 1 mip level currently

/**
 @abstract Experimental method that creates a fixed-size texture. 
 @discussion You cannot modify the size later with -setData. 
 Use this when you're creating a texture to back a render-to-texture operation. Textures created with this method are immutable. 
 @param pixelFormat What pixel format the texture should have
 @param width The new width of the texture
 @param height The new height of the texture
 */
- (id)initEmptyTextureWithPixelFormat:(WMTexture2DPixelFormat)pixelFormat width:(GLuint)width height:(GLuint)height;

/** @abstract If true, width or height of the texture may not be modified by one of the -setData APIs */
@property (nonatomic, readonly) BOOL immutable;

/** @abstract Resize the texture to the provided size and upload new data to it, setting the orientation.
 @param data A pointer to image data in the correct pixel format, or NULL. If NULL, allocate a backing of the provided size with no content.
 @param pixelFormat What pixel format the texture should have
 @param width The new width of the texture
 @param height The new height of the texture
 @param orientation The new orientation of the texture
 */
- (void)setData:(const void*)data pixelFormat:(WMTexture2DPixelFormat)pixelFormat pixelsWide:(GLuint)width pixelsHigh:(GLuint)height contentSize:(CGSize)size orientation:(UIImageOrientation)orientation;
- (void)setData:(const void*)data pixelFormat:(WMTexture2DPixelFormat)pixelFormat pixelsWide:(GLuint)width pixelsHigh:(GLuint)height contentSize:(CGSize)size;



/**
 @abstract Move a texture to the current context from another context.
 @discussion This method changes the texture's context. You can use this method to set up producer-consumer schemes for texture streaming, etc.
 */

- (void)moveToContext:(WMEAGLContext *)inContext;

/** @abstract Equivalent to binding the texture and glTexImage2D with NULL data */
- (void)discardData;

//This is just metadata that's used by WMQuad and possibly other patches to determine how to interpret the image
@property (nonatomic) UIImageOrientation orientation;

/** @abstract The current pixelFormat of the texture. This may change after a call to -setData... */
@property (nonatomic, readonly) WMTexture2DPixelFormat pixelFormat;

/** @abstract The internal width of the texture */
@property (nonatomic, readonly) GLuint pixelsWide;
/** @abstract The internal height of the texture */
@property (nonatomic, readonly) GLuint pixelsHigh;

/** @abstract The nominal size of the texture in points. */
@property (nonatomic, readonly) CGSize contentSize;

/** @abstract The maximum S coordinate of the texture. Usually 1.0. */
@property (nonatomic, readonly) GLfloat maxS;

/** @abstract The maximum H coordinate of the texture. Usually 1.0. */
@property (nonatomic, readonly) GLfloat maxT;
@end

#if TARGET_OS_IPHONE
@interface WMTexture2D (File)
/** @abstract Create a BGRA8888 texture from a PNG file. */
- (id)initWithContentsOfFile:(NSString *)inFilePath;
@end
#endif

@interface WMTexture2D (CGBitmapContext)
/**
 @abstract Convenience method to create a texture by drawing into a CGBitmapContext
 @discussion Use this to draw arbitrary CPU graphics into a texture.
 */
- (id)initWithBitmapSize:(CGSize)size block:(void(^)(CGContextRef ctx))block;

/**
 @abstract Convenience method to create a texture by drawing into a CGBitmapContext
 @discussion Use this to draw arbitrary CPU graphics into a texture.
 @param format The pixel format to use. At the moment, only kWMTexture2DPixelFormat_BGRA8888 and kWMTexture2DPixelFormat_R8 are supported (where available).
 */
- (id)initWithBitmapSize:(CGSize)size format:(WMTexture2DPixelFormat)format block:(void(^)(CGContextRef ctx))block;

@end


@interface WMTexture2D (Image)
#if TARGET_OS_IPHONE
/**
 @abstract Create a WMTexture2D object from a UIImage.
 @discussion RGBA type textures will have their alpha premultiplied.
 @param image The image to upload. Must be non-null.
 */
- (id)initWithImage:(UIImage *)image;

/**
 @abstract Scale up or down a UIImage to create a WMTexture2D.
 @discussion RGBA type textures will have their alpha premultiplied.
 @param image The image to upload. Must be non-null.
 @param scale The scale factor. Must be > 0.0 */
- (id)initWithImage:(UIImage *)image scale:(CGFloat)scale;
#endif

/**
 @abstract Scale up or down a CGImageRef to create a WMTexture2D.
 @discussion RGBA type textures will have their alpha premultiplied.
 @param image The image to upload. Must be non-null.
 @param scale The scale factor. Must be > 0.0
 @param orientation The image orientation */
- (id)initWithCGImage:(CGImageRef)image scale:(CGFloat)scale orientation:(UIImageOrientation)inOrientation;
@end

#if TARGET_OS_IPHONE
@interface WMTexture2D (Text)
/**
 @abstract Create a WMTexture2D object by drawing a string of text.
 @discussion Note that the generated textures are of type kWMTexture2DPixelFormat_A8.
 */
- (id)initWithString:(NSString*)string dimensions:(CGSize)dimensions alignment:(UITextAlignment)alignment fontName:(NSString*)name fontSize:(CGFloat)size;
@end

#endif
