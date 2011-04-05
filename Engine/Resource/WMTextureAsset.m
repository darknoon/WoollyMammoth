//
//  WMTextureAsset.m
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/15/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "WMTextureAsset.h"

#import "Texture2D.h"
#import "WMTextureCubeMap.h"

NSString *const WMTextureAssetTypeCubeMap = @"cubemap";

@implementation WMTextureAsset

@synthesize type;

- (id)initWithResourceName:(NSString *)inResourceName properties:(NSDictionary *)inProperties assetManager:(WMAssetManager *)inAssetManager;
{
	self = [super initWithResourceName:inResourceName properties:inProperties assetManager:inAssetManager];
	if (!self) return nil;
	
	self.type = [inProperties objectForKey:@"type"];
	
	return self;
}

- (BOOL)loadWithBundle:(NSBundle *)inBundle error:(NSError **)outError;
{
	if (isLoaded) return NO;
	
	
	if ([type isEqualToString:@"cubemap"]) {
		NSArray *suffixes = [NSArray arrayWithObjects:@"_x+", @"_x-", @"_y+", @"_y-", @"_z+", @"_z-", nil];
		
		NSMutableArray *images = [NSMutableArray array];
		for (NSString *suffix in suffixes) {
			NSString *fileName = [[resourceName stringByAppendingString:suffix] stringByAppendingPathExtension:@"png"];
			[self requireAssetFileSynchronous:fileName];
			NSString *imagePath = [[inBundle bundlePath] stringByAppendingPathComponent:fileName];
			UIImage *image = [UIImage imageWithContentsOfFile:imagePath];
			[images addObject:image];
		}
		texture = [[WMTextureCubeMap alloc] initWithCubeMapImages:images];
	} else {
		//File comes with extension
		NSString *imagePath = [[inBundle bundlePath] stringByAppendingPathComponent:resourceName];
		
		[self requireAssetFileSynchronous:resourceName];
		texture = [[Texture2D alloc] initWithContentsOfFile:imagePath];
	}
	return texture != nil;
}

- (GLuint)glTexture;
{
	return texture.name;
}


- (void) dealloc
{	
	[texture release];
	[type release];
	type = nil;

	[super dealloc];
}

@end
