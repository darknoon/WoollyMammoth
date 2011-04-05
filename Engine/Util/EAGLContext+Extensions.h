//
//  EAGLContext+Extensions.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 4/5/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>


#import <OpenGLES/EAGL.h>


@interface EAGLContext (EAGLContext_Extensions)

- (NSSet *)supportedExtensions;

//At the moment, just a convenience method
- (BOOL)supportsExtension:(NSString *)inExtension;

@end
