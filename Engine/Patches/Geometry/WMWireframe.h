//
//  WMWireframe.h
//  WMEdit
//
//  Created by Andrew Pouliot on 10/28/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import "WMPatch.h"

@class WMRenderObjectPort;
@interface WMWireframe : WMPatch

@property (nonatomic, strong, readonly) WMRenderObjectPort *inputObject;

@property (nonatomic, strong, readonly) WMRenderObjectPort *outputObject;

@end
