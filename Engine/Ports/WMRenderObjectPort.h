//
//  WMRenderablePort.h
//  WMEdit
//
//  Created by Andrew Pouliot on 7/27/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMPort.h"

@class WMRenderObject;
@interface WMRenderObjectPort : WMPort

@property (nonatomic, copy) WMRenderObject *object;

@end
