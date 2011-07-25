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
	GLuint program;

	NSString *vertexShader;
	NSString *pixelShader;

	NSArray *uniformNames;
	NSMutableDictionary *uniformLocations;
}

//TODO: - (id)initWithDualShaderText:(NSString *)inString;

- (id)initWithVertexShader:(NSString *)inVertexShader pixelShader:(NSString *)inPixelShader;

@property (nonatomic, copy, readonly) NSArray *vertexAttributeNames;
@property (nonatomic, copy, readonly) NSArray *uniformNames;


//Is this program configured correctly for drawing?
- (BOOL)validateProgram;

//TODO: 
@property (nonatomic) BOOL vertexShaderCompatibleWithPointRendering;

//TODO: make these more private
@property (nonatomic, readonly) GLuint program;
- (int)attributeLocationForName:(NSString *)inName;
- (int)uniformLocationForName:(NSString *)inName;

@end


//TODO: where should this live?
@interface WMShader (WMShader_Uniform_State)

//TODO: support multiple-input, ie 3 vec3s instead of 1
- (BOOL)setIntValue:(int)inValue forUniform:(NSString *)inUniform;
- (BOOL)setFloatValue:(float)inValue forUniform:(NSString *)inUniform;
- (BOOL)setVector2Value:(GLKVector2)inValue forUniform:(NSString *)inUniform;
- (BOOL)setVector3Value:(GLKVector3)inValue forUniform:(NSString *)inUniform;
- (BOOL)setVector4Value:(GLKVector4)inValue forUniform:(NSString *)inUniform;
- (BOOL)setMatrix3Value:(GLKMatrix3)inValue forUniform:(NSString *)inUniform;
- (BOOL)setMatrix4Value:(GLKMatrix4)inValue forUniform:(NSString *)inUniform;

@end