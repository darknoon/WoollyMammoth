//
//  WMBufferPort.h
//  WMEdit
//
//  Created by Andrew Pouliot on 10/15/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import "WMPort.h"

@class WMStructuredBuffer;

@interface WMBufferPort : WMPort

//TODO: add a required buffer format for compatibilty?

@property (nonatomic, retain) WMStructuredBuffer *object;

@end
