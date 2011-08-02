//
//  WMImageLoader.h
//  QCParse
//
//  Created by Andrew Pouliot on 4/12/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMPatch.h"

@class WMImagePort;
@interface WMImageLoader : WMPatch

@property (nonatomic, retain) NSData *imageData;

//TODO: WMImagePort
@property (retain, nonatomic) WMImagePort *outputImage;

@end
