//
//  WMModelPOD.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/15/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ModelPOD.h"
#import "WMAsset.h"
#import "WMRenderableDataSource.h"

@interface WMModelPOD : WMAsset <WMRenderableDataSource> {
	CPVRTModelPOD *podmodel;
	SPODMesh mesh;
	float scale;
}

/**
 Properties supported:
 scale: scale the model by this factor when loading
 */

@property (nonatomic, assign) float scale;

- (void *)interleavedDataPointer;


@end
