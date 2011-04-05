//
//  WMSceneDescription.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/28/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMAsset.h"

@class WMGameObject;
@class WMEngine;

/*
 * A WMSceneDescription handles deserializing an object graph from a scene definition file.
 */

@interface WMSceneDescription : WMAsset {
	NSDictionary *sceneDescription;
}


//Engine is set on the input objects, and the assetManager associated with the engine is used to get other associated objects
- (WMGameObject *)deserializeObjectGraphWithEngine:(WMEngine *)inEngine error:(NSError **)outError;

@end
