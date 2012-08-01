//
//  WMRenderInImage.h
//  Particulon
//
//  Created by Andrew Pouliot on 4/24/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMPatch.h"


@interface WMRenderInImage : WMPatch

@property (nonatomic, readonly) WMRenderObjectPort *inputObject1;
@property (nonatomic, readonly) WMRenderObjectPort *inputObject2;
@property (nonatomic, readonly) WMRenderObjectPort *inputObject3;
@property (nonatomic, readonly) WMRenderObjectPort *inputObject4;

@property (nonatomic, readonly) WMColorPort *inputClearColor;

@property (nonatomic, readonly) WMIndexPort *inputWidth;
@property (nonatomic, readonly) WMIndexPort *inputHeight;

@property (nonatomic, readonly) WMImagePort *outputImage;


@end
