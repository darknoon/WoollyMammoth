//
//  WMAudioPort.h
//  WMEdit
//
//  Created by Andrew Pouliot on 5/28/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import "WMPort.h"

@class WMAudioBuffer;
@interface WMAudioPort : WMPort

@property (nonatomic, strong) WMAudioBuffer *buffer;

@end
