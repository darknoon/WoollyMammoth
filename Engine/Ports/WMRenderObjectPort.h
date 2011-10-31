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

//TODO: we shouldn't be hanging onto this value, ie the port should be marked transient and that defined
@property (nonatomic, copy) WMRenderObject *object;

@end
