//
//  WMGLStateObject.h
//  WMEdit
//
//  Created by Andrew Pouliot on 10/9/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMRenderCommon.h"

@class WMEAGLContext;
/**
 @discussion An abstract base class of objects that belong to a WMEAGLContext.
 It is not recommended to create your own subclasses of WMGLStateObject.
 */
@interface WMGLStateObject : NSObject

/**
 @abstract The associated GL context
 @discussion Every state object is associated with the context that it was created in. This provides safety in mating the object-oriented API with the OpenGL state machine.
 */
@property (nonatomic, weak, readonly) WMEAGLContext *context;

@end
