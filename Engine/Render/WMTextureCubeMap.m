//
//  WMTextureCubeMap.m
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 12/7/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "WMTextureCubeMap.h"


@implementation WMTextureCubeMap

- (id)initWithCubeMapImages:(NSArray *)inImages;
{
	self = [super init];
	if (!self) return nil;
	
	//Make sure we have an array of 6 images
	if (inImages.count != 6) {
		NSLog(@"Could not make cube map: not 6 images!");
		[self release];
		return nil;
	}
	
	CGSize imageSize = [[inImages objectAtIndex:0] size];
	for (UIImage *image in inImages) {
		if (!CGSizeEqualToSize(image.size, imageSize)) {
			NSLog(@"Could not make cube map: unequal image size!");
			[self release];
			return nil;
		}
	}
	
	glGenTextures(1, &_name);
	glBindTexture(GL_TEXTURE_CUBE_MAP, _name);
	
	_width = imageSize.width;
	_height = imageSize.height;
	
	//RGB_ (888_) data
	unsigned char *bitmapData888_ = malloc(_width * _height * 4);
	//Will be converted to this
	unsigned char *bitmapData565 = malloc(_width * _height * 2);
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(bitmapData888_, _width, _height, 8, 4 * _width, colorSpace, kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Big);
	CGColorSpaceRelease(colorSpace);
	colorSpace = NULL;
	
	for (int i=0; i<6; i++) {
		UIImage *image = [inImages objectAtIndex:i];
		//Draw image into context
	
		CGContextDrawImage(context, (CGRect){.size = imageSize}, [image CGImage]);
		
		//Convert "RRRRRRRRGGGGGGGGBBBBBBBBAAAAAAAA" to "RRRRRGGGGGGBBBBB"
		unsigned int*			inPixel32 = (unsigned int *)bitmapData888_;
		unsigned short*			outPixel16 = (unsigned short *)bitmapData565;		
		for (int i=0; i < _width * _height; ++i, ++inPixel32) {
			//TODO: dither this
			*outPixel16++ = ((((*inPixel32 >> 0) & 0xFF) >> 3) << 11) | ((((*inPixel32 >> 8) & 0xFF) >> 2) << 5) | ((((*inPixel32 >> 16) & 0xFF) >> 3) << 0);
		}
		
		//Upload 565 data
		glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, GL_RGB, _width, _height, 0, GL_RGB, GL_UNSIGNED_SHORT_5_6_5, bitmapData565);		
		
		//Upload 8888 data
		//glTexImage2D(GL_TEXTURE_CUBE_MAP_POSITIVE_X + i, 0, GL_RGBA, _width, _height, 0, GL_RGBA, GL_UNSIGNED_BYTE, bitmapData888_);

	}
	GL_CHECK_ERROR;
	glTexParameteri(GL_TEXTURE_CUBE_MAP, 
                    GL_TEXTURE_MIN_FILTER, 
                    GL_LINEAR_MIPMAP_LINEAR); 
    glTexParameteri(GL_TEXTURE_CUBE_MAP, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

	GL_CHECK_ERROR;
	
	CGContextRelease(context);
	free(bitmapData888_);
	free(bitmapData565);
		
	glGenerateMipmap(GL_TEXTURE_CUBE_MAP);

	GL_CHECK_ERROR;

	//Unbind texture
	glBindTexture(GL_TEXTURE_CUBE_MAP, 0);
	
	return self;
}

@end
