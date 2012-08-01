//
//  WMImageOrientation.h
//  Take
//
//  Created by Andrew Pouliot on 8/1/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import "WMPatch.h"

@interface WMImageOrientation : WMPatch

@property (nonatomic, readonly) WMImagePort *inputImage;

@property (nonatomic, readonly) WMIndexPort *outputOrientation;

@end
