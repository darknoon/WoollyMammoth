//
//  WMImageResize.h
//  WMEdit
//
//  Created by Andrew Pouliot on 10/5/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import "WMPatch.h"

@interface WMImageResize : WMPatch

@property (nonatomic, strong) WMVector2Port *inputFactors;

@property (nonatomic, strong) WMImagePort *inputImage;

@property (nonatomic, strong) WMImagePort *outputImage;

@end
