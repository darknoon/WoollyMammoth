//
//  WMAsset.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/15/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WMAssetManager;

@interface WMAsset : NSObject {
	WMAssetManager *assetManager;
	NSString *resourceName;
	NSDictionary *properties;
	BOOL isLoaded;
}

@property BOOL isLoaded;

- (id)initWithResourceName:(NSString *)inResourceName properties:(NSDictionary *)inProperties assetManager:(WMAssetManager *)inAssetManager;

- (BOOL)isLoaded;
- (BOOL)loadWithBundle:(NSBundle *)inBundle error:(NSError **)outError;

- (BOOL)requireAssetFileSynchronous:(NSString *)inAssetRelativePath;

@end
