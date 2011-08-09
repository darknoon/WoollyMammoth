//
//  WMImageLoader.m
//  QCParse
//
//  Created by Andrew Pouliot on 4/12/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMImageLoader.h"

#import "WMTexture2D.h"
#import "WMImagePort.h"

NSString *const WMImageLoaderImageDataKey = @"imageData";

@implementation WMImageLoader
@synthesize outputImage;
@synthesize imageData;

+ (NSString *)category;
{
    return WMPatchCategoryImage;
}

+ (void)load;
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self registerToRepresentClassNames:[NSSet setWithObject:NSStringFromClass([self class])]];
	[pool drain];
}

- (BOOL)setPlistState:(id)inPlist;
{
	//TODO: should we check that the image is valid for use here?
	self.imageData = [inPlist objectForKey:WMImageLoaderImageDataKey];

	return [super setPlistState:inPlist];
}

- (void)dealloc;
{
	[imageData release];
	
	[super dealloc];
}

- (id)plistState;
{
	NSMutableDictionary *state = [[super plistState] mutableCopy];
	
	if (self.imageData) {
		[state setObject:imageData forKey:WMImageLoaderImageDataKey];
	}
	
	return [state autorelease];
}

- (BOOL)setup:(WMEAGLContext *)context;
{
	//TODO: add preload image option
	return YES;
}

- (BOOL)execute:(WMEAGLContext *)context time:(double)time arguments:(NSDictionary *)args;
{
	if (imageData && !outputImage.image) {
		UIImage *uiImage = [UIImage imageWithData:imageData];
		if (!uiImage) {
			NSLog(@"Couldn't load image data!");
		}
		WMTexture2D *texture = [[WMTexture2D alloc] initWithImage:uiImage];
		outputImage.image = texture;
		[texture release];
		return texture != nil;
	} else {
		//Presumably data will be added later?
		return YES;
	}
}

@end
