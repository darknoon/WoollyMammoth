//
//  WMAssetManager.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/15/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WMEngine;

@interface WMAssetManager : NSObject {
	WMEngine *engine; //weak
	NSBundle *assetBundle;
	
	NSURL *remoteBundleURL;
	
	NSDictionary *manifest;
	NSMutableDictionary *models;
	NSMutableDictionary *shaders;
	NSMutableDictionary *textures;
	NSMutableDictionary *scripts;
	NSMutableDictionary *scenes;
}

@property (nonatomic, retain) NSURL *remoteBundleURL;
@property (nonatomic, readonly, retain) NSBundle *assetBundle;

- (id)initWithBundlePath:(NSString *)inBundlePath engine:(WMEngine *)inEngine;

- (id)initWithRemoteBundleURL:(NSURL *)inBundleURL engine:(WMEngine *)inEngine;

- (id)objectForManifestKey:(NSString *)inManifestKey;

- (id)modelWithName:(NSString *)inName;
- (id)shaderWithName:(NSString *)inName;
- (id)textureWithName:(NSString *)inName;
- (id)sceneWithName:(NSString *)inName;
- (id)scriptWithName:(NSString *)inName;

//Must be called with a context set
- (void)loadAllAssetsSynchronous;


@end
