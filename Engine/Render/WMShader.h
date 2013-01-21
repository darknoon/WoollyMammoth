//
//  WMShader.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/13/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMGLStateObject.h"


extern NSString *WMShaderErrorDomain;

typedef enum {
	WMShaderErrorCompileError = 1,
	WMShaderErrorLinkError,
} WMShaderError;

/**
 @abstract Represents an OpenGL program object
 @discussion A shader is associated with the OpenGL context that was active at its time of creation.

 You can set the uniforms for the vertex and shader when rendering by using WMRenderObject's -setValue:forUniformNamed: method.
 
 Methods that take a single file or string as input use shader #ifdefs to compile both the vertex and fragment shaders from the same text. This helps to avoid the effort of making sure that the inputs of the fragment shader are the same as the outputs of the vertex shader. If you would like to specify the vertex and fragment shaders separately, use the initWithVertexShader: fragmentShader:error: method.
 
 Use #ifdef VERTEX_SHADER or FRAGMENT_SHADER to compile vertex and fragment componenents.

 */
@interface WMShader : WMGLStateObject

/** @abstract Load a shader from the main bundle as a single file with the vertex and fragment shaders.
 @discussion  Load from main bundle as one .glsl file. This method does not do any caching logic like UIImage, so it is the client's responsibility to only initialize one copy of the shader per OpenGL context.
 @param name The name of the shader in the main bundle
 @param outError In case of an error, an error may be written to this pointer describing the error
 @return A shader if shader compilation is successful, or nil if there was an error
 */
+ (WMShader *)shaderNamed:(NSString *)name error:(NSError **)outError;

/** @abstract Load vertex and fragment shaders from a single glsl file
 @param path The file path to the shader
 @param outError In case of an error, an error may be written to this pointer describing the error
 @return A shader if shader compilation is successful, or nil if there was an error
 */
+ (WMShader *)shaderWithContentsOfFile:(NSString *)path error:(NSError **)outError;

/** @abstract Load vertex and fragment shaders from a single glsl file
 @discussion  Load vertex and fragment shaders from a single glsl file
 @param path The file path to the shader
 @param outError In case of an error, an error may be written to this pointer describing the error
 @return A shader if shader compilation is successful, or nil if there was an error
 */
- (id)initWithContentsOfFile:(NSString *)path error:(NSError **)outError;

/** @abstract Load vertex and fragment shaders from a string
 @param string A string containing the program text
 @param outError In case of an error, an error may be written to this pointer describing the error
 @return A shader if shader compilation is successful, or nil if there was an error
 */
- (id)initWithShaderText:(NSString *)string error:(NSError **)outError;

/** @abstract Load vertex and fragment shaders from separate strings
 @param vertexShaderText A string containing the vertex shader
 @param fragmentShaderText A string containing the fragment shader
 @param outError In case of an error, an error may be written to this pointer describing the error
 @return A shader if shader compilation is successful, or nil if there was an error
 */
- (id)initWithVertexShader:(NSString *)vertexShaderText fragmentShader:(NSString *)fragmentShaderText error:(NSError **)outError;

/** @abstract The names of the vertex attributes in the compiled program.
 @discussion If an attribute is not used in the shader, it may not appear in this list.
 */
@property (nonatomic, copy, readonly) NSArray *vertexAttributeNames;

/** @abstract The names of active uniforms in the compiled program.
 @discussion If a uniform is not used in the shader, it may not appear in this list.
 */
@property (nonatomic, copy, readonly) NSArray *uniformNames;

/** @abstract A basic shader
 @discussion The defaultShader has instructions for rendering with a vertex ("position") and texture coordinate ("texCoord0"). It takes as input a transformation matrix "wm_T", a texture, and a color.
 
 The shader will be similar to the following:
 
	varying highp vec2 v_tc;

	#if VERTEX_SHADER

	uniform mat4 wm_T;

	attribute vec4 position;
	attribute vec2 texCoord0;

	void main() {
		gl_Position = wm_T * position;
		v_tc = texCoord0;
	}

	#elif FRAGMENT_SHADER

	uniform sampler2D texture;
	uniform lowp vec4 color;

	void main() {
		gl_FragColor = color * texture2D(texture, v_tc);
	}

	#endif
 
 
 
 */
+ (WMShader *)defaultShader;

/** @abstract Check if this program is configured correctly for drawing */
- (BOOL)validateProgram;

//TODO:- (BOOL)validateProgramWithError:(NSError *)errorDescription;
//TODO: move to the EAGLContext, because it depends on state outside the shader

//TODO: @property (nonatomic) BOOL vertexShaderCompatibleWithPointRendering;

/** @abstract return a string describing the OpenGL constant in enum.
 @discussion Valid parameters include GL_FLOAT, GL_FLOAT_VEC2, GL_FLOAT_MAT4, etc. Use for debugging.
 @return A string describing compactly the type as it would appear in GLSL. "float", "vec2", "mat4", etc. */
+ (NSString *)nameOfShaderType:(GLenum)inType;

/** @abstract Look up the type of an attribute
 @param attribute The name of the attribute
 @return One of the OpenGL enums describing a GLSL type */
- (GLenum)attributeTypeForName:(NSString *)attribute;

/** @abstract Look up the type of a uniform
 @param uniform The name of the uniform
 @return One of the OpenGL enums describing a GLSL type */
- (GLenum)uniformTypeForName:(NSString *)uniform;

/** @abstract Get the size of a shader attribute input
 @discussion For an input of array type like vec3[2], this would return 2. For inputs like float, vec3, mat4, etc this will be 1. Currently, attributes and uniforms of array type are UNSUPPORTED by WMEAGLContext's rendering API. */
- (int)attributeSizeForName:(NSString *)inAttributeName;

/** @abstract Get the size of a shader uniform input
 @discussion For an input of array type like vec3[2], this would return 2. For inputs like float, vec3, mat4, etc this will be 1. Currently, attributes and uniforms of array type are UNSUPPORTED by WMEAGLContext's rendering API. */
- (int)uniformSizeForName:(NSString *)inUniformName;

@end
