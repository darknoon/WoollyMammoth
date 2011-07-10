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

//TODO: Should we support this? All it will be is 111.n.1000.. showing how many attributes are included...
//@property (nonatomic, assign) unsigned int attributeMask;

- (int)attributeLocationForName:(NSString *)inName;
- (int)uniformLocationForName:(NSString *)inName;

//Is this program configured correctly for drawing?
- (BOOL)validateProgram;

//Use this to draw
//TODO: deprecate this in favor of the WMEAGLContext managing the currently bound program
@property (nonatomic, readonly) GLuint program;

@end
