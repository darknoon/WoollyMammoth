//
//  WMShader.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/13/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMRenderCommon.h"

//ASSUME: Shader must be used in only one GL context.

@interface WMShader : NSObject
//TODO: - (id)initWithDualShaderText:(NSString *)inString;

- (id)initWithVertexShader:(NSString *)inVertexShader fragmentShader:(NSString *)inPixelShader error:(NSError **)outError;

@property (nonatomic, copy, readonly) NSArray *vertexAttributeNames;
@property (nonatomic, copy, readonly) NSArray *uniformNames;

//Is this program configured correctly for drawing?
- (BOOL)validateProgram;

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
