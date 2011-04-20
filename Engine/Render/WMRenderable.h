//
//  WMRenderable.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/13/10.
//  Copyright 2010 Darknoon. All rights reserved.
//


//Renders a Model


#import <Foundation/Foundation.h>

#import "WMRenderCommon.h"
#import "WMPatch.h"

#import "Matrix.h"

@class WMShader;
@class WMTextureAsset;
@class WMModelPOD;
@class WMEngine;


extern NSString *WMRenderableBlendModeAdd;
extern NSString *WMRenderableBlendModeNormal;


@interface WMRenderable : WMPatch {
	WMShader *shader;
	//TODO: how should we handle multi-texturing?
	//Move into shader?
}

@property (nonatomic, copy) NSString *blendMode;

- (id)initWithEngine:(WMEngine *)inEngine properties:(NSDictionary *)renderableRepresentation;

@property (nonatomic, assign) NSObject *inputModel;
@property (nonatomic, assign) WMTextureAsset *inputTexture;
@property (nonatomic, assign) NSString *inputBlendMode;

//Gets called after every frame. do computation here
- (void)update;

@end
