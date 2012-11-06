//
//  WMImageFilter.h
//  WMViewer
//
//  Created by Andrew Pouliot on 5/20/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

//For now, hardcoded to a gaussan filter

#import "WMPatch.h"
#import "WMPorts.h"
#import "WMRenderCommon.h"

@class WMShader;
@class WMFramebuffer;
@class WMTexture2D;
@class WMStructuredBuffer;

@interface WMImageFilter : WMPatch

@property (nonatomic, readonly) WMNumberPort *inputRadius;
@property (nonatomic, readonly) WMImagePort *inputImage;
@property (nonatomic, readonly) WMImagePort *outputImage;


@end
