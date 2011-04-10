//
//  WMShader.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/13/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMRenderCommon.h"

#import "WMAsset.h"
//ASSUME: Shader must be used in only one GL context.

typedef enum {
	WMShaderAttributePosition = 0,
	WMShaderAttributePosition2d,
	WMShaderAttributeNormal,
	WMShaderAttributeColor,
	WMShaderAttributeTexCoord0,
	WMShaderAttributeTexCoord1,
	WMShaderAttributeCount, //How many attributes we have defined
} WMShaderAttribute;

extern NSString *const WMShaderAttributeNamePosition;  // "position"
extern NSString *const WMShaderAttributeNamePosition2d;  // "position2d"
extern NSString *const WMShaderAttributeNameNormal;    // "normal"
extern NSString *const WMShaderAttributeNameColor;     // "color"
extern NSString *const WMShaderAttributeNameTexCoord0; // "texCoord0"
extern NSString *const WMShaderAttributeNameTexCoord1; // "texCoord1"

@interface WMShader : WMAsset {
	//TODO: Add ES1 Pipeline features?
	
	//If rendering with ES2
	NSArray *uniformNames;
	NSString *vertexShader;
	NSString *pixelShader;
	unsigned int attributeMask;

	GLuint program;
	NSMutableDictionary *uniformLocations;
}

+ (NSString *)nameForShaderAttribute:(NSUInteger)shaderAttribute;

@property (nonatomic, assign) unsigned int attributeMask;

/**
 Supported properties:
 uniformNames[]		Array of uniform names
 
 */

@property (nonatomic, copy, readonly) NSArray *uniformNames;
@property (nonatomic, copy, readonly) NSString *vertexShader;
@property (nonatomic, copy, readonly) NSString *pixelShader;

//Is this program configured correctly for drawing?
- (BOOL)validateProgram;

//Use this to draw
@property (nonatomic, readonly) GLuint program;
- (int)uniformLocationForName:(NSString *)inName;

@end
