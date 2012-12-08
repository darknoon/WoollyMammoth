//
//  EAGLContext+Extensions.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 4/5/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>


#import "WMEAGLContext.h"

@interface WMEAGLContext (EAGLContext_Extensions)

- (NSSet *)supportedExtensions;

- (BOOL)supportsExtension:(NSString *)inExtension;

@end
