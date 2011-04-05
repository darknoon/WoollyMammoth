//
//  WMAssetManager.m
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/15/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "WMAssetManager.h"

#import "WMEngine.h"

//Asset classes
#import "WMModelPOD.h"
#import "WMShader.h"
#import "WMTextureAsset.h"
#import "WMSceneDescription.h"
#import "WMLuaScript.h"

//Fixed assets
#import "WMQuad.h"
#import "WMSphere.h"
#import "WMCameraInputTexture.h"

#import "WMAssetManifest.h"

const NSUInteger WMAssetManagerManifestMinimumVersionReadable = 1;

@interface WMAssetManager ()
- (void)createAssetsFromManifest:(NSDictionary *)inManifest;
- (void)addFixedAssets;
@end


@implementation WMAssetManager

@synthesize remoteBundleURL;
@synthesize assetBundle;

- (id)initWithBundlePath:(NSString *)inBundlePath engine:(WMEngine *)inEngine;
{
	self = [super init];
	if (!self) return nil;
	
	engine = inEngine;
	
	assetBundle = [[NSBundle alloc] initWithPath:inBundlePath];

	NSString *manifestPath = [assetBundle pathForResource:@"manifest" ofType:@"plist"];
	manifest = [[NSDictionary dictionaryWithContentsOfFile:manifestPath] retain];
	if (!manifest) {
		NSLog(@"No manifest.plist found for bundle %@, or manifest could not be read", inBundlePath);
		[self release];
		return nil;
	}
	
	models = [[NSMutableDictionary alloc] init];
	shaders = [[NSMutableDictionary alloc] init];
	textures = [[NSMutableDictionary alloc] init];
	scripts = [[NSMutableDictionary alloc] init];
	scenes = [[NSMutableDictionary alloc] init];
	
	[self addFixedAssets];
	[self createAssetsFromManifest:manifest];

	return self;
}

+ (NSString *)applicationSupportFolder
{
	NSArray *thePaths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	NSString *theBasePath = ([thePaths count] > 0) ? [thePaths objectAtIndex:0] : NSTemporaryDirectory();
	
	NSString *theBundleName = [[[[NSBundle mainBundle] bundlePath] lastPathComponent] stringByDeletingPathExtension];
	NSString *theApplicationSupportFolder = [theBasePath stringByAppendingPathComponent:theBundleName];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:theApplicationSupportFolder] == NO)
	{
		NSError *theError = NULL;
		if ([[NSFileManager defaultManager] createDirectoryAtPath:theApplicationSupportFolder withIntermediateDirectories:YES attributes:NULL error:&theError] == NO)
			return(NULL);
	}
	
	return(theApplicationSupportFolder);
}

- (id)initWithRemoteBundleURL:(NSURL *)inBundleURL engine:(WMEngine *)inEngine;
{
	NSString *localBundlePath = [[WMAssetManager applicationSupportFolder] stringByAppendingPathComponent:@"Downloaded.wm"];
	[[NSFileManager defaultManager] createDirectoryAtPath:localBundlePath withIntermediateDirectories:YES attributes:nil error:NULL];

	remoteBundleURL = [inBundleURL retain];
	
	//Get manifiest
	//TODO: don't do this synchronously!!!
	NSURL *manifestURL = [inBundleURL URLByAppendingPathComponent:@"manifest.plist"];
	NSDictionary *remoteManifest = [[NSDictionary dictionaryWithContentsOfURL:manifestURL] retain];
	
	if (!remoteManifest) {
		NSLog(@"No manifest.plist found for bundle %@, or manifest could not be read", manifestURL);
		[self release];
		return nil;
	}
	
	//Write the manifest locally
	[remoteManifest writeToFile:[localBundlePath stringByAppendingPathComponent:@"manifest.plist"] atomically:YES];
	
	self = [self initWithBundlePath:localBundlePath engine:inEngine];
	
	return self;
}

- (void) dealloc
{
	[assetBundle release];

	[models release];
	[shaders release];
	[textures release];
	[scripts release];
	[scenes release];
	
	[remoteBundleURL release];

	[super dealloc];
}

- (void)addFixedAssets;
{
	[models setObject:[[[WMQuad alloc] init] autorelease] forKey:@"WMQuad"];
	[models setObject:[[[WMSphere alloc] init] autorelease] forKey:@"WMSphere"];
	[textures setObject:[[[WMCameraInputTexture alloc] initWithResourceName:nil properties:nil assetManager:self] autorelease] forKey:@"CameraInput"];
}

- (void)createAssetsFromManifest:(NSDictionary *)inManifest;
{
	NSDictionary *modelDefinitions = [inManifest objectForKey:WMAssetManagerManifestModelsKey];
	for (NSString *modelKey in modelDefinitions) {
		WMAsset *asset = [[WMModelPOD alloc] initWithResourceName:modelKey properties:[modelDefinitions objectForKey:modelKey] assetManager:self];
		[models setObject:asset forKey:modelKey];
	}
	
	NSDictionary *shaderDefinitions = [inManifest objectForKey:WMAssetManagerManifestShadersKey];
	for (NSString *shaderKey in shaderDefinitions) {
		WMAsset *asset = [[WMShader alloc] initWithResourceName:shaderKey properties:[shaderDefinitions objectForKey:shaderKey] assetManager:self];
		[shaders setObject:asset forKey:shaderKey];
	}
	
	NSDictionary *textureDefinitions = [inManifest objectForKey:WMAssetManagerManifestTexturesKey];
	for (NSString *textureKey in textureDefinitions) {
		WMAsset *asset = [[WMTextureAsset alloc] initWithResourceName:textureKey properties:[textureDefinitions objectForKey:textureKey] assetManager:self];
		[textures setObject:asset forKey:textureKey];
	}
	
	NSDictionary *sceneDefinitions = [inManifest objectForKey:WMAssetManagerManifestScenesKey];
	for (NSString *sceneKey in sceneDefinitions) {
		WMAsset *asset = [[WMSceneDescription alloc] initWithResourceName:sceneKey properties:[sceneDefinitions objectForKey:sceneKey] assetManager:self];
		[scenes setObject:asset forKey:sceneKey];
	}
	
	NSDictionary *scriptDefinitions = [inManifest objectForKey:WMAssetManagerManifestScriptsKey];
	for (NSString *scriptKey in scriptDefinitions) {
		WMAsset *asset = [[WMLuaScript alloc] initWithResourceName:scriptKey properties:[scriptDefinitions objectForKey:scriptKey] assetManager:self];
		[scripts setObject:asset forKey:scriptKey];
	}
	
	
}

- (void)loadAllAssetsSynchronous;
{
	//Load models
	for (WMModelPOD *model in [models allValues]) {
		if ([model isKindOfClass:[WMAsset class]]) {
			NSError *loadError = nil;
			if (![model loadWithBundle:assetBundle error:&loadError]) {
				NSLog(@"Error loading model : %@", model);
			}
		}
	}
	//Load shaders
	for (WMShader *shader in [shaders allValues]) {
		NSError *loadError = nil;
		if (![shader loadWithBundle:assetBundle error:&loadError]) {
			NSLog(@"Error loading shader : %@", shader);
		}		
	}
	//Load textures
	for (WMTextureAsset *texture in [textures allValues]) {
		NSError *loadError = nil;
		if (![texture loadWithBundle:assetBundle error:&loadError]) {
			NSLog(@"Error loading texture : %@", texture);
		}
	}
	//Load scenes
	for (WMSceneDescription *scene in [scenes allValues]) {
		NSError *loadError = nil;
		if (![scene loadWithBundle:assetBundle error:&loadError]) {
			NSLog(@"Error loading scene : %@", scene);
		}
	}
	
	//Load scripts
	for (WMLuaScript *script in [scripts allValues]) {
		NSError *loadError = nil;
		if (![script loadWithBundle:assetBundle inScriptingContext:engine.scriptingContext error:&loadError]) {
			NSLog(@"Error loading script : %@", script);
		}
	}
	
}

- (id)objectForManifestKey:(NSString *)inManifestKey;
{
	return [manifest objectForKey:inManifestKey];
}

- (id)modelWithName:(NSString *)inName;
{
	return [models objectForKey:inName];
}

- (id)shaderWithName:(NSString *)inName;
{
	return [shaders objectForKey:inName];
}

- (id)textureWithName:(NSString *)inName;
{
	return [textures objectForKey:inName];
}

- (id)sceneWithName:(NSString *)inName;
{
	return [scenes objectForKey:inName];
}

- (id)scriptWithName:(NSString *)inName;
{
	return [scripts objectForKey:inName];
}

@end
