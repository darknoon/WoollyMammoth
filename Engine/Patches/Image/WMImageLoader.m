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
#import "WMEngine.h"
#import "WMBundleDocument.h"

//Deprecated
NSString *const WMImageLoaderImageDataKey = @"imageData";

NSString *const WMImageLoaderImageResourceKey = @"imageResource";

@implementation WMImageLoader
@synthesize imageResource;

+ (NSString *)category;
{
    return WMPatchCategoryImage;
}

+ (void)load;
{
	@autoreleasepool {
		[self registerToRepresentClassNames:[NSSet setWithObject:NSStringFromClass([self class])]];
	}
}

- (BOOL)setPlistState:(id)inPlist;
{
	//TODO: should we check that the image is valid for use here?
	self.imageResource = [inPlist objectForKey:WMImageLoaderImageResourceKey];

	return [super setPlistState:inPlist];
}


- (id)plistState;
{
	NSMutableDictionary *state = [[super plistState] mutableCopy];
	
	if (self.imageResource) {
		[state setObject:self.imageResource forKey:WMImageLoaderImageResourceKey];
	}
	
	return state;
}

- (UIImage *)imageInDocument:(WMBundleDocument *)inDocument;
{
	NSFileWrapper *wrapper = [[inDocument resourceWrappers] objectForKey:self.imageResource];
	
	NSString *basePath = [inDocument.fileURL path];
	NSString *path = [basePath stringByAppendingPathComponent:wrapper.filename];
	
	UIImage *uiImage = [UIImage imageWithContentsOfFile:path];
	if (!uiImage) {
		NSLog(@"Couldn't load image data! Path: %@", path);
	}

	return uiImage;
}

- (BOOL)setup:(WMEAGLContext *)context;
{
	//TODO: add preload image option
	return YES;
}

- (BOOL)execute:(WMEAGLContext *)context time:(double)time arguments:(NSDictionary *)args;
{
	WMBundleDocument *document = [args objectForKey:WMEngineArgumentsDocumentKey];
	
	if (!outputImage.image && document && self.imageResource) {
		UIImage *image = [self imageInDocument:document];
		if (image) {
			WMTexture2D *texture = [[WMTexture2D alloc] initWithImage:image];
			outputImage.image = texture;
			return texture != nil;
		} else {
			return NO;
		}
	} else {
		//Presumably data will be added later?
		return YES;
	}
}

@end
