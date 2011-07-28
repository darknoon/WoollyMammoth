//
//  Created by Andrew Pouliot on 7/24/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMEAGLContext.h"
#import "WMStructuredBuffer.h"
#import "WMShader.h"



/*
 * WMRenderObject encapsulates all of the state that needs to come together to render to screen.
 * You can specify vertices simply, or indices (possibly multiple times) and vertices.
 *
 *
 * According to the PowerVR folks who make the GPUs for iOS devices the most efficent setup is to use GL_TRIANGLES
 * with an index buffer and triangle locality (vertices near in the buffer are near in space for cache efficiency.
 * Other rendering types and configurations are supported, however, and YMMV.
 */

@interface WMRenderObject : NSObject

//Create an object that can be rendered to a WMEAGLContext
- (id)init;

@property (nonatomic, retain) WMStructuredBuffer *vertexBuffer;

//Optional. If not specified, will render vertices once, in order
@property (nonatomic, retain) WMStructuredBuffer *indexBuffer;

//If you specify glPoints, you must specify a compatible shader
@property (nonatomic, retain) WMShader *shader;

//One of GL_POINTS, GL_LINES, GL_LINE_LOOP, GL_LINE_STRIP, GL_TRIANGLES, GL_TRIANGLE_STRIP, or GL_TRIANGLE_FAN
//Default is GL_TRIANGLES
@property (nonatomic) GLenum renderType;

//Default (0, NSIntegerMax) will render full buffer. Setting this property will render a subset of the input data vertices or indices (if an index buffer is specified)
@property (nonatomic) NSRange renderRange;

@property (nonatomic) DNGLStateBlendMask renderBlendState;
@property (nonatomic) DNGLStateDepthMask renderDepthState;

- (void)setValue:(id)inValue forUniformWithName:(NSString *)inUniformName;
- (id)valueForUniformWithName:(NSString *)inUniformName;

@end


//The WMEAGLContext will assign us a vao. Do not mess with this outside of WMEAGLContext
@interface WMRenderObject (WMRenderObject_WMEAGLContext_Private)

//TODO: @property (nonatomic) GLenum vertexArrayObject;

@end