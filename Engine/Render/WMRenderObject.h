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

extern NSString *const WMRenderObjectTransformUniformName; // wm_T is selected for brevity
// was modelViewProjectionMatrix

#import "WMGLStateObject.h"

//TODO: implement  <NSCopying>
//This will require having some definition of the VAO state that can persist between different copies of a parent WMRenderObject.
//Perhaps that means making a pool of VAOs associated with the relevant structured buffers / parameters and then associating the correct one as necessary
//Without copying, if we don't execute

@interface WMRenderObject : WMGLStateObject <NSCopying>

//Create an object that can be rendered to a WMEAGLContext
- (id)init;

//TODO: support multiple vertex buffers?
@property (nonatomic, strong) WMStructuredBuffer *vertexBuffer;

//Optional. If not specified, will render vertices once, in order
@property (nonatomic, strong) WMStructuredBuffer *indexBuffer;

//If you specify glPoints, you must specify a compatible shader
@property (nonatomic, strong) WMShader *shader;

//One of GL_POINTS, GL_LINES, GL_LINE_LOOP, GL_LINE_STRIP, GL_TRIANGLES, GL_TRIANGLE_STRIP, or GL_TRIANGLE_FAN
//Default is GL_TRIANGLES
@property (nonatomic) GLenum renderType;

//Default (0, NSIntegerMax) will render full buffer. Setting this property will render a subset of the input data vertices or indices (if an index buffer is specified)
@property (nonatomic) NSRange renderRange;

@property (nonatomic) DNGLStateBlendMask renderBlendState;
@property (nonatomic) DNGLStateDepthMask renderDepthState;
@property (nonatomic) DNGLCullFaceMask cullFaceState;

//These are applied to the WMRenderObjectTransformUniformName key, ie the transformation from VBO coords to world coords, performed in the vertex shader
//The transform can also be set directly to a specific value if that is of use
- (void)premultiplyTransform:(GLKMatrix4)inMatrix;
- (void)postmultiplyTransform:(GLKMatrix4)inMatrix;

- (NSArray *)uniformKeys;
- (void)setValue:(id)inValue forUniformWithName:(NSString *)inUniformName;
- (id)valueForUniformWithName:(NSString *)inUniformName;

@end
