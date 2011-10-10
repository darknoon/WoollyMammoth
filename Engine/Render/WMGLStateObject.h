//
//  WMGLStateObject.h
//  WMEdit
//
//  Created by Andrew Pouliot on 10/9/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WMEAGLContext;
@interface WMGLStateObject : NSObject

//Every state object is associated with the context that it was created in
@property (nonatomic, weak, readonly) WMEAGLContext *context;

@end
