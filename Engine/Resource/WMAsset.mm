//
//  WMAsset.m
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/15/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "WMAsset.h"
#import "WMAssetManager.h"

@implementation WMAsset

@synthesize isLoaded;

- (id)initWithResourceName:(NSString *)inResourceName properties:(NSDictionary *)inProperties assetManager:(WMAssetManager *)inAssetManager;
{
	self = [super init];
	if (!self) return nil;
	
	resourceName = [inResourceName retain];
	properties = [inProperties retain];
	
	assetManager = inAssetManager;
	
	return self;
}


- (void) dealloc
{
	[resourceName release];
	[properties release];
	
	[super dealloc];
}

//TODO: thread safety
- (BOOL)loadWithBundle:(NSBundle *)inBundle error:(NSError **)outError;
{
	NSAssert(0, @"Must overload this");
	return NO;
}

- (NSString *)description;
{
	return [NSString stringWithFormat:@"%@{%@}", [super description], resourceName];
}

- (BOOL)requireAssetFileSynchronous:(NSString *)inAssetRelativePath;
{
	if (assetManager.remoteBundleURL) {
		NSURL *remoteURL = [assetManager.remoteBundleURL URLByAppendingPathComponent:inAssetRelativePath];
		//Copy the file to the local bundle
		NSData *data = [NSData dataWithContentsOfURL:remoteURL];
		if (!data) 
			return NO;
		if (![data writeToFile:[[assetManager.assetBundle bundlePath] stringByAppendingPathComponent:inAssetRelativePath] atomically:YES]) 
			return NO;
		
	}
	return YES;
}

@end
