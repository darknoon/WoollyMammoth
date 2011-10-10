//
//  WMGLStateObject_WMEAGLContext_Private.h
//  WMEdit
//
//  Created by Andrew Pouliot on 10/9/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import "WMGLStateObject.h"

@interface WMGLStateObject ()

@property (nonatomic, weak, readwrite) WMEAGLContext *context;

//In this method, you know that the context still exists and is bound
- (void)deleteInternalState;

@end
