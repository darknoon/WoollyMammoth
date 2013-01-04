//
//  WMShader.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/13/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMGLStateObject.h"

//TODO: define shader error domain and some error codes

@interface WMShader : WMGLStateObject
//Load from main bundle as one .glsl file (Does not currently include any caching logic)
+ (WMShader *)shaderNamed:(NSString *)name error:(NSError **)outError;
+ (WMShader *)shaderWithContentsOfFile:(NSString *)path error:(NSError **)outError;

- (id)initWithContentsOfFile:(NSString *)path error:(NSError **)outError;

//Use #ifdef VERTEX_SHADER or FRAGMENT_SHADER to compile vertex and fragment componenents
- (id)initWithShaderText:(NSString *)inString error:(NSError **)outError;

- (id)initWithVertexShader:(NSString *)inVertexShader fragmentShader:(NSString *)inPixelShader error:(NSError **)outError;

@property (nonatomic, copy, readonly) NSArray *vertexAttributeNames;
@property (nonatomic, copy, readonly) NSArray *uniformNames;

+ (WMShader *)defaultShader;

//Is this program configured correctly for drawing?
- (BOOL)validateProgram;
//TODO:- (BOOL)validateProgramWithError:(NSError *)errorDescription;
//TODO: move to the EAGLContext, because it depends on state outside the shader

//TODO: @property (nonatomic) BOOL vertexShaderCompatibleWithPointRendering;

+ (NSString *)nameOfShaderType:(GLenum)inType;

- (GLenum)attributeTypeForName:(NSString *)inAttributeName;
- (GLenum)uniformTypeForName:(NSString *)inUniformName;

// for an vec3[2], this would be 2. Most commonly, this will be 1.
// Currently, attributes and uniforms of this type are UNSUPPORTED by WMEAGLContext's rendering API
- (int)attributeSizeForName:(NSString *)inAttributeName;
- (int)uniformSizeForName:(NSString *)inUniformName;

@end

extern NSString *WMShaderErrorDomain;
typedef enum {
	WMShaderErrorCompileError = 1,
	WMShaderErrorLinkError,
} WMShaderError;
