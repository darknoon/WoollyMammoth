//
//  WMTextureAsset.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/15/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMAsset.h"

#import "WMRenderCommon.h"

@class Texture2D;

extern NSString *const WMTextureAssetTypeCubeMap;

@interface WMTextureAsset : WMAsset {
	Texture2D *texture;
	
	NSString *type;
}

//AWFUL HACK::
- (id)initWithTexture:(Texture2D *)inTexture;

@property (nonatomic, copy) NSString *type;

- (GLuint)glTexture;

@end
