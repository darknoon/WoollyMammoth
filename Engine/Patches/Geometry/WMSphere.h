//
//  WMSphere.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 12/6/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMPatch.h"

//Should render a nice sphere. Right now does a janky one :P
@interface WMSphere : WMPatch

@property (nonatomic, strong, readonly) WMIndexPort *inputUCount;
@property (nonatomic, strong, readonly) WMIndexPort *inputVCount;
@property (nonatomic, strong, readonly) WMNumberPort *inputRadius;
@property (nonatomic, strong, readonly) WMImagePort *inputImage;

//TODO: Allow rendering partial spheres
//@property (nonatomic, strong, readonly) WMNumberPort *inputRhoStart;
//@property (nonatomic, strong, readonly) WMNumberPort *inputRhoEnd;
//@property (nonatomic, strong, readonly) WMNumberPort *inputPhiStart;
//@property (nonatomic, strong, readonly) WMNumberPort *inputPhiEnd;

@property (nonatomic, strong, readonly) WMRenderObjectPort *outputSphere;

@end
