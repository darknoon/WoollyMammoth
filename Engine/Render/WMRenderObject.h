//
//  Created by Andrew Pouliot on 7/24/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMEAGLContext.h"
#import "WMStructuredBuffer.h"
#import "WMShader.h"

/*! The name of the uniform that represents the model-view-perspective transform in the default shaders. */
extern NSString *const WMRenderObjectTransformUniformName; // wm_T is selected for brevity

#import "WMGLStateObject.h"

/*!
 @class      WMRenderObject
 @abstract   Represents an object to render to the screen.
 @discussion WMRenderObject encapsulates all of the state that needs to come together to render to screen. You can provide a vertex buffer alone, or vertex buffer and index buffer and vertices. A WMShader and the uniforms control the programmable pipeline. The uniform with the special key WMRenderObjectTransformUniformName or "wm_T" is the complete tranform function for the default shader ie the model-view-perspective transform matrix. premultiplyTransform and postMultiplyTransform operate on this uniform value, but you may define whatever behavior is desired in your own vertex shaders and ignore this functionality.

 Parts of the OpenGL state necessary to render this object can be specified with renderDepthState, renderBlendState, etc.
 
 According to the PowerVR folks who make the GPUs for iOS devices the most efficent setup is to use GL_TRIANGLES with an index buffer and triangle locality (vertices near in the buffer are near in space for cache efficiency). Other rendering types and configurations are supported, however, and YMMV.

 */
@interface WMRenderObject : WMGLStateObject <NSCopying>

/*! The designated initializer: create an object that can be rendered to a WMEAGLContext */
- (id)init;

/*! An interleaved vertex buffer. In the future, multiple vertex buffers for the various attributes may be supported. */
@property (nonatomic, strong) WMStructuredBuffer *vertexBuffer;

/*! A buffer of indices in the vertexBuffer to render with glDrawElements().
    Optional (default is nil). If not specified, WMRenderObject will render vertices once, in order with glDrawArrays() */
@property (nonatomic, strong) WMStructuredBuffer *indexBuffer;

/*! Shader with which to render the geometry. If you set the renderType to GL_POINTS, you must specify a compatible shader. A shader must be provided to render.
 
 @seealso WMShader WMShader defaultShader. */
@property (nonatomic, strong) WMShader *shader;

/*! Rendering mode for OpenGL. Specify one of GL_POINTS, GL_LINES, GL_LINE_LOOP, GL_LINE_STRIP, GL_TRIANGLES, GL_TRIANGLE_STRIP, or GL_TRIANGLE_FAN from gl.h.
 Default is GL_TRIANGLES.
 */
@property (nonatomic) GLenum renderType;

/*! Specify a sub-range of the input data vertices or indices (if an index buffer is specified) to render.
Default (0, NSIntegerMax) will render the range in the buffer. */
@property (nonatomic) NSRange renderRange;

/*! Use this to set how the rendering should be blended with the framebuffer. Possible values are the keys from WMBlendMode. */
@property (nonatomic) WMBlendMode renderBlendState;

/*! Use this to enable or disable depth testing or depth writing (z-buffer). If depth testing is enabled, samples must pass the depth test to show up on screen. If depth writing is enabled, rendering will write depth information to the depth buffer. */
@property (nonatomic) WMDepthMask renderDepthState;

/*! 
 These are applied to the WMRenderObjectTransformUniformName key, ie the transformation from vertex coords to world coords, performed in the vertex shader
 The transform can also be set directly to a specific value if that is of use with -setValue:forUniformWithName:
  */

/* @param inMatrix
 The matrix to pre-multiply with the transformation matrix uniform "wm_T". */
- (void)premultiplyTransform:(GLKMatrix4)inMatrix;

/* @param inMatrix
 The matrix to post-multiply with the transformation matrix uniform "wm_T". */
- (void)postmultiplyTransform:(GLKMatrix4)inMatrix;

/*! The keys that have been set on the render object. */
- (NSArray *)uniformKeys;

/*!
 Set the value for a uniform specified in the shader. A uniform may be set that does not exist in the shader, but this has no effect.
 
 */
- (void)setValue:(id)inValue forUniformWithName:(NSString *)inUniformName;

/*! Retrieve a value set with -setValue:forUniformWithName: */
- (id)valueForUniformWithName:(NSString *)inUniformName;

/*! Use this to identify objects as they pass throught the system */
@property (nonatomic, copy) NSString *debugLabel;

@end
