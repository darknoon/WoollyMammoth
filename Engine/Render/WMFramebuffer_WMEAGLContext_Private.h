//
//  WMFramebuffer_WMEAGLContext_Private.h
//  WMEdit
//
//  Created by Andrew Pouliot on 10/9/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#ifndef WMEdit_WMFramebuffer_WMEAGLContext_Private_h
#define WMEdit_WMFramebuffer_WMEAGLContext_Private_h

#import "WMEAGLContext.h"
#import "WMFramebuffer.h"

@interface WMEAGLContext (FramebufferPrivate)

//This also controls glViewport at the moment. Perhaps this will change in the future.
@property (nonatomic, strong) WMFramebuffer *boundFramebuffer;
@property (nonatomic) CGRect viewport;

@end

#endif
