/*

File: WMTexture2D.m
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

#import "WMRenderCommon.h"

#import "WMTexture2D.h"

#import "WMTexture2D_WMEAGLContext_Private.h"
#import "WMGLStateObject_WMEAGLContext_Private.h"

NSString *NSStringFromUIImageOrientation(UIImageOrientation orientation);

NSString *NSStringFromUIImageOrientation(UIImageOrientation orientation) {
	switch (orientation) {
		default:
		case UIImageOrientationUp:
			return @"default orientation (up)";
		case UIImageOrientationDown:
			return @"180 deg rotation (down)";
		case UIImageOrientationLeft:
			return @"90 deg CCW (left)";
		case UIImageOrientationRight:
			return @"90 deg CW (right)";
		case UIImageOrientationUpMirrored:
			return @"horizontal flip (up mirror)";
		case UIImageOrientationDownMirrored:
			return @"vertical flip (down mirror)";
		case UIImageOrientationLeftMirrored:
			return @"90 deg CW, flipped (left mirror)";
		case UIImageOrientationRightMirrored:
			return @"90 deg CCW, flipped (right mirror)";
	}
}

@interface WMTexture2D ()
- (void)setData:(const void*)data pixelFormat:(WMTexture2DPixelFormat)pixelFormat pixelsWide:(NSUInteger)width pixelsHigh:(NSUInteger)height contentSize:(CGSize)size;

@property (nonatomic, readonly) GLuint name;

@end

//CLASS IMPLEMENTATIONS:

@implementation WMTexture2D

@synthesize orientation;
@synthesize contentSize=_size;
@synthesize pixelFormat=_format;
@synthesize pixelsWide=_width;
@synthesize pixelsHigh=_height;
@synthesize name=_name;


- (void)createDefaultTexture;
{
	glGenTextures(1, &_name);
	[self.context bind2DTextureNameForModification:_name inBlock:^{
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		//Needed by default for npot
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	}];

}

- (id)initWithData:(const void*)data pixelFormat:(WMTexture2DPixelFormat)pixelFormat pixelsWide:(NSUInteger)width pixelsHigh:(NSUInteger)height contentSize:(CGSize)size orientation:(UIImageOrientation)inOrientation;
{
	self = [self init];
	if (!self) return nil;

	[self createDefaultTexture];
	
	ZAssert(self.context, @"Weird! No context in which to create texture!");
	[self setData:data pixelFormat:pixelFormat pixelsWide:width pixelsHigh:height contentSize:size orientation:inOrientation];
	
	return self;
}

- (id)initWithData:(const void*)data pixelFormat:(WMTexture2DPixelFormat)pixelFormat pixelsWide:(NSUInteger)width pixelsHigh:(NSUInteger)height contentSize:(CGSize)size;
{
	return [self initWithData:data pixelFormat:pixelFormat pixelsWide:width pixelsHigh:height contentSize:size orientation:UIImageOrientationUp];
}

- (void)setData:(const void*)data pixelFormat:(WMTexture2DPixelFormat)pixelFormat pixelsWide:(NSUInteger)width pixelsHigh:(NSUInteger)height contentSize:(CGSize)size orientation:(UIImageOrientation)inOrientation;
{
	ZAssert(self.context, @"Weird! No context in which to set data!");
	[self.context bind2DTextureNameForModification:_name inBlock:^{
		switch(pixelFormat) {
				
			case kWMTexture2DPixelFormat_RGBA8888:
				glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
				break;
			case kWMTexture2DPixelFormat_BGRA8888:
#if GL_APPLE_texture_format_BGRA8888
				glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_BGRA_EXT, GL_UNSIGNED_BYTE, data);
#else
				glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_BGRA, GL_UNSIGNED_BYTE, data);
#endif
				break;
			case kWMTexture2DPixelFormat_RGB565:
				glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_SHORT_5_6_5, data);
				break;
			case kWMTexture2DPixelFormat_A8:
				glTexImage2D(GL_TEXTURE_2D, 0, GL_ALPHA, width, height, 0, GL_ALPHA, GL_UNSIGNED_BYTE, data);
				break;
			default:
				[NSException raise:NSInternalInconsistencyException format:@""];
				
		}
	}];
	
	_size = size;
	_width = width;
	_height = height;
	_format = pixelFormat;
	orientation = inOrientation;

}

- (void)setData:(const void*)data pixelFormat:(WMTexture2DPixelFormat)pixelFormat pixelsWide:(NSUInteger)width pixelsHigh:(NSUInteger)height contentSize:(CGSize)size;
{
	[self setData:data pixelFormat:pixelFormat pixelsWide:width pixelsHigh:height contentSize:size orientation:UIImageOrientationUp];
}

- (void)discardData;
{
	[self setData:NULL pixelFormat:_format pixelsWide:_width pixelsHigh:_height contentSize:_size];
}

- (GLfloat)maxS;
{
	return _size.width / (float)_width;
}

- (GLfloat)maxT;
{
	return _size.height / (float)_height;
}

- (void)deleteInternalState;
{
	if(_name) {
		glDeleteTextures(1, &_name);
		[self.context forgetTexture2DName:_name];
		_name = 0;
	}
}

- (void)moveToContext:(WMEAGLContext *)inContext;
{
	if (inContext.sharegroup == self.context.sharegroup) {
		[EAGLContext setCurrentContext:self.context];
		if (self.context) {		
			[self.context forgetTexture2DName:_name];
		}
		glFlush();
		self.context = inContext;
	} else {
		DLog(@"Cannot move texture %@ to context %@ because they do not have the same sharegroup!");
	}
}
- (NSString *)description
{
	return [NSString stringWithFormat:@"<%@ %p = %i>", [self class], self, _name];
}


- (NSString *)debugDescription
{
	return [NSString stringWithFormat:@"<%@ = %p | Name = %i | Dimensions = %ix%i | Coordinates = (%.2f, %.2f) | orientation = %@>", [self class], self, self.name, self.pixelsWide, self.pixelsHigh, self.maxS, self.maxT, NSStringFromUIImageOrientation(orientation)];
}

@end

@implementation WMTexture2D (File)

- (id)initWithContentsOfFile:(NSString *)inFilePath;
{
#if TARGET_OS_IPHONE
	NSString *extension = [inFilePath pathExtension];
	if ([extension isEqualToString:@"png"]) {
		UIImage *image = [UIImage imageWithContentsOfFile:inFilePath];
		return [self initWithImage:image];
	}
#else
#endif
	return nil;
}

@end




@implementation WMTexture2D (Image)

#if TARGET_OS_IPHONE

- (id)initWithImage:(UIImage *)uiImage scale:(CGFloat)inScale
{
	return [self initWithCGImage:uiImage.CGImage scale:inScale orientation:uiImage.imageOrientation];
}


- (id)initWithImage:(UIImage *)uiImage
{
	return [self initWithImage:uiImage scale:1.0f];
}

#endif

- (id)initWithCGImage:(CGImageRef)image scale:(CGFloat)inScale orientation:(UIImageOrientation)inOrientation;
{
	
	if(image == NULL) {
		NSLog(@"Could not create texture: UIImage is null.");
		return nil;
	}
	
	self = [self init];
	if (!self) return nil;

	[self createDefaultTexture];

	NSUInteger i;
	CGContextRef			context = nil;
	void*					data = nil;;
	CGColorSpaceRef			colorSpace;
	void*					tempData;
	BOOL					hasAlpha;
	CGImageAlphaInfo		info;
	CGSize					imageSize;
	WMTexture2DPixelFormat  pixelFormat;
	int                     maxTextureSize = [self.context maxTextureSize];
	
	
	info = CGImageGetAlphaInfo(image);
	hasAlpha = ((info == kCGImageAlphaPremultipliedLast) || (info == kCGImageAlphaPremultipliedFirst) || (info == kCGImageAlphaLast) || (info == kCGImageAlphaFirst) ? YES : NO);
//	if(CGImageGetColorSpace(image)) {
//		if(hasAlpha)
//			pixelFormat = kWMTexture2DPixelFormat_RGBA8888;
//		else
//			pixelFormat = kWMTexture2DPixelFormat_RGB565;
//	} else  //NOTE: No colorspace means a mask image
//		pixelFormat = kWMTexture2DPixelFormat_A8;
	pixelFormat = kWMTexture2DPixelFormat_RGBA8888;
	
	
	imageSize = CGSizeMake(CGImageGetWidth(image) * inScale, CGImageGetHeight(image) * inScale);
		
	//Constrain loaded image into the maximum texture size
	NSUInteger width = imageSize.width;
	NSUInteger height = imageSize.height;
	
	while((width > maxTextureSize) || (height > maxTextureSize)) {
		width /= 2;
		height /= 2;
		imageSize.width *= 0.5;
		imageSize.height *= 0.5;
	}
	//Ensure we'll never have textures with less than 1px dimension on either axis, leading to a 0-size malloc()
	width = MAX(1, width);
	height = MAX(1, height);
	
	switch(pixelFormat) {		
		case kWMTexture2DPixelFormat_RGBA8888:
			colorSpace = CGColorSpaceCreateDeviceRGB();
			data = malloc(height * width * 4);
			context = CGBitmapContextCreate(data, width, height, 8, 4 * width, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
			CGColorSpaceRelease(colorSpace);
			break;
		case kWMTexture2DPixelFormat_RGB565:
			colorSpace = CGColorSpaceCreateDeviceRGB();
			data = malloc(height * width * 4);
			context = CGBitmapContextCreate(data, width, height, 8, 4 * width, colorSpace, kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Big);
			CGColorSpaceRelease(colorSpace);
			break;
			
		case kWMTexture2DPixelFormat_A8:
			data = malloc(height * width);
			context = CGBitmapContextCreate(data, width, height, 8, width, NULL, kCGImageAlphaOnly);
			break;				
		default:
			[NSException raise:NSInternalInconsistencyException format:@"Invalid pixel format"];
	}
	
	
	CGContextClearRect(context, CGRectMake(0, 0, width, height));
	CGContextTranslateCTM(context, 0, height - imageSize.height);
	
	CGContextDrawImage(context, CGRectMake(0, 0, imageSize.width, imageSize.height), image);

	if(pixelFormat == kWMTexture2DPixelFormat_RGB565) {
		//Convert "RRRRRRRRRGGGGGGGGBBBBBBBBAAAAAAAA" to "RRRRRGGGGGGBBBBB"
		unsigned int*			inPixel32;
		unsigned short*			outPixel16;

		tempData = malloc(height * width * 2);
		inPixel32 = (unsigned int*)data;
		outPixel16 = (unsigned short*)tempData;
		for(i = 0; i < width * height; ++i, ++inPixel32)
			*outPixel16++ = ((((*inPixel32 >> 0) & 0xFF) >> 3) << 11) | ((((*inPixel32 >> 8) & 0xFF) >> 2) << 5) | ((((*inPixel32 >> 16) & 0xFF) >> 3) << 0);
		free(data);
		data = tempData;
	}
	
	[self setData:data pixelFormat:pixelFormat pixelsWide:width pixelsHigh:height contentSize:imageSize orientation:inOrientation];
	
	CGContextRelease(context);
	free(data);
	
	return self;
}


@end


@implementation WMTexture2D (Text)

#if TARGET_OS_IPHONE

- (id)initWithString:(NSString*)string dimensions:(CGSize)dimensions alignment:(UITextAlignment)alignment fontName:(NSString*)name fontSize:(CGFloat)size
{
	NSUInteger				width,
							height,
							i;
	CGContextRef			context;
	void*					data;
	CGColorSpaceRef			colorSpace;
	UIFont *				font;
	
	font = [UIFont fontWithName:name size:size];
	
	width = dimensions.width;
	if((width != 1) && (width & (width - 1))) {
		i = 1;
		while(i < width)
		i *= 2;
		width = i;
	}
	height = dimensions.height;
	if((height != 1) && (height & (height - 1))) {
		i = 1;
		while(i < height)
		i *= 2;
		height = i;
	}
	
	colorSpace = CGColorSpaceCreateDeviceGray();
	data = calloc(height, width);
	context = CGBitmapContextCreate(data, width, height, 8, width, colorSpace, kCGImageAlphaNone);
	CGColorSpaceRelease(colorSpace);
	
	
	CGContextSetGrayFillColor(context, 1.0, 1.0);
	CGContextTranslateCTM(context, 0.0, height);
	CGContextScaleCTM(context, 1.0, -1.0); //NOTE: NSString draws in UIKit referential i.e. renders upside-down compared to CGBitmapContext referential
	UIGraphicsPushContext(context);
		[string drawInRect:CGRectMake(0, 0, dimensions.width, dimensions.height) withFont:font lineBreakMode:UILineBreakModeWordWrap alignment:alignment];
	UIGraphicsPopContext();
	
	self = [self initWithData:data pixelFormat:kWMTexture2DPixelFormat_A8 pixelsWide:width pixelsHigh:height contentSize:dimensions orientation:UIImageOrientationUp];
	
	CGContextRelease(context);
	free(data);
	
	return self;
}

#endif

@end

