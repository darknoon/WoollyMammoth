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

@interface WMShader : NSObject {
	NSMutableDictionary *uniformLocations;
}

//TODO: - (id)initWithDualShaderText:(NSString *)inString;

- (id)initWithVertexShader:(NSString *)inVertexShader fragmentShader:(NSString *)inPixelShader error:(NSError **)outError;

@property (nonatomic, copy, readonly) NSArray *vertexAttributeNames;
@property (nonatomic, copy, readonly) NSArray *uniformNames;

//Is this program configured correctly for drawing?
- (BOOL)validateProgram;

//TODO: @property (nonatomic) BOOL vertexShaderCompatibleWithPointRendering;

//TODO: make these more private
@property (nonatomic, readonly) GLuint program;
- (int)attributeLocationForName:(NSString *)inName;
- (int)uniformLocationForName:(NSString *)inName;

+ (NSString *)nameOfShaderType:(GLenum)inType;

- (GLenum)attributeTypeForName:(NSString *)inAttributeName;
- (GLenum)uniformTypeForName:(NSString *)inUniformName;

- (int)attributeCountForName:(NSString *)inAttributeName;
- (int)uniformForName:(NSString *)inUniformName;


@end

extern NSString *WMShaderErrorDomain;
typedef enum {
	WMShaderErrorCompileError = 1,
	WMShaderErrorLinkError,
} WMShaderError;
