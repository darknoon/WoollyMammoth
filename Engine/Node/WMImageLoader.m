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

@implementation WMImageLoader
@synthesize outputImage;

+ (void)load;
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self registerToRepresentClassNames:[NSSet setWithObject:@"QCImageLoader"]];
	[pool drain];
}

- (id)initWithPlistRepresentation:(id)inPlist;
{
	self = [super initWithPlistRepresentation:inPlist];
	if (!self) return nil;
	
	//TODO: improve this
	//	NSDictionary *state = [inPlist objectForKey:WMPatchStatePlistName];
	NSDictionary *state = [inPlist objectForKey:@"state"];

	NSData *imageData = [state objectForKey:@"imageData"];
	if (imageData) {
		UIImage *uiImage = [UIImage imageWithData:imageData];
		if (!uiImage) {
			NSLog(@"Couldn't load image data!");
		}
		outputImage.image = [[WMTexture2D alloc] initWithImage:uiImage];
	}
	
	return self;
}

@end
