//
//  WMRenderableDataSource.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/21/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMRenderCommon.h"
#import "WMEAGLContext.h"

#import "WMStructuredBuffer.h"

//TODO: redefine this protocol in light of arbitrary data passing
@protocol WMRenderableDataSource

- (BOOL)renderInContext:(WMEAGLContext *)inContext;

@end
