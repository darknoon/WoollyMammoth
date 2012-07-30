//
//  WMImageSize.h
//  WMEdit
//
//  Created by Andrew Pouliot on 7/27/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import "WMPatch.h"

@interface WMImageSize : WMPatch

//An image
@property (nonatomic, readonly) WMImagePort *inputImage;

// Size of the image in pixels
@property (nonatomic, readonly) WMIndexPort *outputWidth;
@property (nonatomic, readonly) WMIndexPort *outputHeight;

// 1.0 / imageSize
@property (nonatomic, readonly) WMVector2Port *outputSizeInv;

@end
