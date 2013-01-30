//
//  EAGLContext+Extensions.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 4/5/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>


#import "WMEAGLContext.h"

@interface WMEAGLContext (Extensions)

/** @name Extensions */

/**
 @abstract A set of all extensions supported the OpenGL context associated with a WMEAGLContext.
 */
- (NSSet *)supportedExtensions;

/**
 @abstract Query at runtime whether the OpenGL context associated with a WMEAGLContext can support a given extension.
 @discussion
 
     #if GL_OES_vertex_array_object
 
     if ([context supportsExtension:@"GL_OES_vertex_array_object"]) {
          
     }
 
     #endif
 
 @return true iff the given extension string matches exactly with a supported extension
 */
- (BOOL)supportsExtension:(NSString *)inExtension;

@end
