//
//  Created by Andrew Pouliot on 7/24/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMEAGLContext.h"
#import "WMStructuredBuffer.h"
#import "WMShader.h"

typedef NS_ENUM(int, WMBlendMode) {
	WMBlendModeAdd = 3,
	WMBlendModeSourceOver = 1,
	WMBlendModeReplace = 0,
	
	//Deprecated, do not use. For compatibility only!
	DNGLStateBlendEnabled = 1 << 0,
	DNGLStateBlendModeAdd = 1 << 1,
};

typedef NS_ENUM(int, WMDepthMask) {
	WMDepthTestEnabled  = 1 << 0,
	WMDepthWriteEnabled = 1 << 1,
	
	//Deprecated, do not use. For compatibility only!
	DNGLStateDepthTestEnabled  = WMDepthTestEnabled,
	DNGLStateDepthWriteEnabled = WMDepthWriteEnabled,
};


/** The name of the uniform that represents the model-view-perspective transform in the default shaders. */
extern NSString *const WMRenderObjectTransformUniformName; // wm_T is selected for brevity

#import "WMGLStateObject.h"

/**
 @abstract   Represents an object to render to the screen. Instances should be kept around for efficency if similar OpenGL state is desired for rendering again.
 @discussion WMRenderObject encapsulates all of the state that needs to come together to render to screen.
 
 Configure with a vertex buffer alone, or a vertex buffer and an index buffer.
 
 A shader and uniforms control the programmable pipeline. The uniform with the special key WMRenderObjectTransformUniformName or "wm_T" is the complete tranform function for the default shader ie the model-view-perspective transform matrix. premultiplyTransform and postMultiplyTransform operate on this uniform value, but you may define whatever behavior is desired in your own vertex shaders and ignore this functionality.

 OpenGL state pertinent to rendering this object can be specified with renderDepthState, renderBlendState, etc.

 According to the PowerVR folks who make the GPUs for iOS devices the most efficent setup is to use GL_TRIANGLES with an index buffer and triangle locality (vertices near in the buffer are near in space for cache efficiency). Other rendering types and configurations are supported, however, and YMMV.

 @warning While this class declares itself to conform to NSCopying, this is strictly for internal use only. Copying WMRenderObject is not recommended.

 */
@interface WMRenderObject : WMGLStateObject

/** @name Creation */

/** @abstract The designated initializer: creates an empty render object. */
- (id)init;


/** @name Geometry data */

/** @abstract An interleaved structured vertex buffer containing all of the attributes for rendering. In the future, multiple vertex buffers for the various attributes may be supported via a separate property. */
@property (nonatomic, strong) WMStructuredBuffer *vertexBuffer;

/**
 @abstract A buffer of indices in the vertexBuffer to render with glDrawElements().
 @discussion indexBuffer is optional (default is nil).
 If not specified, WMRenderObject will render vertices once, in order, with glDrawArrays()
 */
@property (nonatomic, strong) WMStructuredBuffer *indexBuffer;

/** @name OpenGL state */

/**
 @abstract Shader with which to render the geometry.
 @discussion If you set the renderType to GL_POINTS, you must specify a compatible shader. A shader must be provided to render.
 
 See also: +[WMShader defaultShader]. */
@property (nonatomic, strong) WMShader *shader;

/** @abstract Rendering mode for OpenGL.
 Specify one of GL_POINTS, GL_LINES, GL_LINE_LOOP, GL_LINE_STRIP, GL_TRIANGLES, GL_TRIANGLE_STRIP, or GL_TRIANGLE_FAN from gl.h.
 Default is GL_TRIANGLES.
 */
@property (nonatomic) GLenum renderType;

/** @abstract Specify a sub-range of the input data vertices or indices (if an index buffer is specified) to render.
Default (0, NSIntegerMax) will render the range in the buffer. */
@property (nonatomic) NSRange renderRange;

/** @abstract Use this to set how the rendering should be blended with the framebuffer. Possible values are the keys from WMBlendMode. */
@property (nonatomic) WMBlendMode renderBlendState;

/*! @abstract Use this to enable or disable depth testing or depth writing (z-buffer). If depth testing is enabled, samples must pass the depth test to show up on screen. If depth writing is enabled, rendering will write depth information to the depth buffer.
 
 - To use the z-buffer with opaque geometry, use (WMDepthTestEnabled | WMDepthWriteEnabled).
 
 - Once you have rendered your opaque geometry and want to render some transparent surfaces that are occluded by the opaque objects, (WMDepthTestEnabled) will let one transparent surface draw over another. Note that you must render your transparent objects back-to-front to achieve correct display.
 
 - If have only transparent surfaces, set the renderDepthState to 0, ie don't use the z-buffer. This is useful for rendering UI on top of a 3d scene, or if your whole scene contains transparent surfaces. If you do not use the z-buffer, make sure depthBufferDepth = 0 is set on your WMView or WMFramebuffer to avoid wasting memory for a z-buffer.
 
 */
@property (nonatomic) WMDepthMask renderDepthState;

/** @name Uniforms */

/*! The keys that have been set on the render object. */
- (NSArray *)uniformKeys;

/*!
 Set the value for a uniform specified in the shader. A uniform may be set that does not exist in the shader, but this has no effect. Uniforms may be used in the vertex and/or fragment shaders.
 
 Uniforms are inputs to a shader that do not change per-vertex or per-fragment: they are the same for the whole WMRenderObject / draw call.
 
 Use uniforms to set which textures will be bound during rendering this object. Textures in the uniforms array will be uniqued and only bound to one sampler at a time.
 
  In the following table NSValue[X] denotes an NSValue whose type is @encode(X). See the NSValue categories provided with WM for easy conversion to and from these types. For UIColor and NSColor, the value's color will be converted to RGB or RGBA floating-point components.
 
   Uniform Definition | Accepted Value Types
  ------------------- | ---------------------------------------------------
   uniform sampler2D  | WMTexture2D, WMCVTexture2D
   uniform vec4       | NSValue[GLKVector4], UIColor / NSColor
   uniform vec3       | NSValue[GLKVector3], UIColor / NSColor
   uniform vec2       | NSValue[GLKVector2]
   uniform mat4       | NSValue[GLKMatrix4]
   uniform mat3       | NSValue[GLKMatrix3]
   uniform mat2       | *unsupported*
   uniform float      | NSNumber, NSValue[float]
   uniform int        | NSNumber
 
 For example, if your shader is:
 
	varying lowp vec4 v_color;

	#ifdef VERTEX_SHADER

	attribute vec4 position;
	attribute vec4 color;

	uniform float size;
 
	void main() {
		gl_Position = position;
		gl_PointSize = size;
		v_color = color;
	}
	
	#elif FRAGMENT_SHADER
	
	uniform sampler2D sTexture;

	void main() {
		gl_FragColor = v_color * texture2D(sTexture, gl_PointCoord);
	}

	#endif
 
 Then you would set the uniforms size and sTexture as so:
 
	[object setValue:@(1.0f) forUniformName:@"size"];
 	[object setValue:[[WMTexture2D alloc] initWithImage: ...] forUniformName:@"sTexture"];
 
  
 @param value A value for the uniform of a class appropriate for the type specified in the shader.
 @param uniformName The name of the uniform in the vertex or fragment shader.
 
 */

- (void)setValue:(id)value forUniformWithName:(NSString *)uniformName;

/*! Retrieve a value set with -setValue:forUniformWithName: */
- (id)valueForUniformWithName:(NSString *)inUniformName;


/**
 @abstract Multiply a matrix with the WMRenderObjectTransformUniformName key, ie the transformation from vertex coords to world coords, performed in the vertex shader
 @discussion The transform can also be set directly to a specific value if that is of use with -setValue:forUniformWithName:
 @param matrix The matrix to pre-multiply with the transformation matrix uniform "wm_T". */
- (void)premultiplyTransform:(GLKMatrix4)matrix;

/**
 @abstract Multiply a matrix with the WMRenderObjectTransformUniformName key, ie the transformation from vertex coords to world coords, performed in the vertex shader
 @discussion The transform can also be set directly to a specific value if that is of use with -setValue:forUniformWithName:
 @param matrix The matrix to post-multiply with the transformation matrix uniform "wm_T". */
- (void)postmultiplyTransform:(GLKMatrix4)matrix;

/** @name Debugging */

/*! Use this tag to identify objects as they pass through the rendering pipeline. */
@property (nonatomic, copy) NSString *debugLabel;

@end
