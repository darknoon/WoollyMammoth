//
//  WMQuad.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/21/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMPatch.h"
#import "WMRenderCommon.h"

//Just renders a quad, nothing special :)
@class WMShader;
@class WMImagePort;
@class WMNumberPort;
@class WMColorPort;
@class WMStructuredBuffer;

@interface WMQuad : WMPatch

@property (nonatomic, strong, readonly) WMImagePort *inputImage;
@property (nonatomic, strong, readonly) WMVector3Port *inputPosition;
@property (nonatomic, strong, readonly) WMNumberPort *inputScale;
@property (nonatomic, strong, readonly) WMNumberPort *inputRotation;
@property (nonatomic, strong, readonly) WMColorPort *inputColor;

@property (nonatomic, strong, readonly) WMIndexPort *inputSubU;
@property (nonatomic, strong, readonly) WMIndexPort *inputSubV;

@property (nonatomic, strong, readonly) WMIndexPort *inputBlending;

@property (nonatomic, strong, readonly) WMRenderObjectPort *outputObject;


@end
