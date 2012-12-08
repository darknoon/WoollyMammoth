//
//  DNPCPostProcess.h
//  ParticleCascade
//
//  Created by Andrew Pouliot on 9/20/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WMTexture2D;
@class WMFramebuffer;

@interface DNPCPostProcess : NSObject

- (void)processTexture:(WMTexture2D *)texture renderToFramebuffer:(WMFramebuffer *)outputFramebuffer;

@end
