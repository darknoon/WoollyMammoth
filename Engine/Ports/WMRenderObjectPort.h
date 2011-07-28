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

//TODO: this should really be copy, as we need to move its value over
//TODO: we shouldn't be hanging onto this value.
//Maybe we could use nilling weak references here to get rid of the object when it's no longer relevant?
@property (nonatomic, retain) WMRenderObject *object;

@end
