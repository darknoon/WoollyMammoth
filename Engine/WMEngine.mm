//
//  WMEngine.m
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/12/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "WMEngine.h"

#import "WMDebugChannel.h"
#import "WMGameObject.h"
#import "WMScriptingContext.h"
#import "WMRenderable.h"
#import "WMAssetManager.h"
#import "WMSceneDescription.h"

//For Debug method only
#import "WMModelPOD.h"
#import "WMQuad.h"
#import "WMTextureAsset.h"

@interface WMEngine ()
@property (nonatomic, retain, readwrite) WMGameObject *rootObject;

@end


@implementation WMEngine

@synthesize assetManager;
@synthesize renderEngine;
@synthesize rootObject;
@synthesize scriptingContext;
@synthesize debugChannel;

- (id) init {
	self = [super init];
	if (self == nil) return self; 
	
	objectsById = [[NSMutableDictionary alloc] initWithCapacity:256];
	
	return self;
}


- (void)dealloc
{
	[assetManager release];
	[rootObject release];
	[objectsById release];
	[scriptingContext release];
	[debugChannel release];
	[renderEngine release];

	[super dealloc];
}

- (void)debugMakeObjectGraph;
{
	WMModelPOD *sphereModel = [assetManager modelWithName:@"GeodesicSphere02"];
	WMShader *positionShader = [assetManager shaderWithName:@"DebugPositionOnly"];

	MATRIX transform;
	for (int i=0; i<1; i++) {
		WMGameObject *child = [self createObject];
		child.renderable = [[[WMRenderable alloc] init] autorelease];
		child.renderable.model = sphereModel;
		child.renderable.shader = positionShader;
		
		MatrixTranslation(transform, 0, 10.9 * i, 0);
		child.transform = transform;
		
		[self.rootObject addChild:child];
	}
	
	WMQuad *quadModel = [[[WMQuad alloc] init] autorelease];
	
	WMShader *textureShader = [assetManager shaderWithName:@"DebugPositionTexture"];
	WMTextureAsset *texture = [assetManager textureWithName:@"TestTexture.png"];
	WMGameObject *debugQuad = [self createObject];
	debugQuad.renderable = [[[WMRenderable alloc] init] autorelease];
	debugQuad.renderable.model = quadModel;
	debugQuad.renderable.shader = textureShader;
	debugQuad.renderable.texture = texture;
	
	const float scaleFactor = 30.0f;
	MATRIX scale;
	MatrixScaling(scale, scaleFactor, scaleFactor, scaleFactor);
	debugQuad.transform = scale;

	[self.rootObject addChild:debugQuad];
}


- (void)start;
{
#if DEBUG
	if (!debugChannel) {
		debugChannel = [[WMDebugChannel alloc] initWithEngine:self onPort:8080];
		[debugChannel start];
	}
	if (!scriptingContext) {
		scriptingContext = [[WMScriptingContext alloc] initWithEngine:self];
	}
#endif
	if (!assetManager) {
		assetManager = [[WMAssetManager alloc] initWithBundlePath:[[NSBundle mainBundle] pathForResource:@"WeatherGlobe" ofType:@"wm"] engine:self];
	}
	[assetManager loadAllAssetsSynchronous];

	//Deserialize object graph
	WMSceneDescription *scene = [assetManager sceneWithName:@"scene"];
	
	NSError *sceneReadError = nil;
	self.rootObject = [scene deserializeObjectGraphWithEngine:self error:&sceneReadError];	
}

- (void)updateRecursive:(WMGameObject *)inGameObject;
{
	[inGameObject update];
	for (WMGameObject *object in inGameObject.children) {
		[self updateRecursive:object];
	}
}

- (void)update;
{
	[self updateRecursive:rootObject];
}

- (WMGameObject *)createObject;
{
	WMGameObject *object = [[WMGameObject alloc] initWithObjectId:++maxObjectId inEngine:self];
	[objectsById setObject:object forKey:[NSNumber numberWithUnsignedLongLong:object.objectId]];
	return [object autorelease];
}

- (void)deleteObject:(WMGameObject *)inObject;
{
	for (WMGameObject *child in inObject.children) {
		[self deleteObject:child];
	}
	[inObject removeFromParent];
}

- (WMGameObject *)objectWithId:(UInt64)gameObjectId;
{
	return [objectsById objectForKey:[NSNumber numberWithUnsignedLongLong:gameObjectId]];
}

- (NSString *)title;
{
	return [assetManager objectForManifestKey:@"title"];
}

@end
