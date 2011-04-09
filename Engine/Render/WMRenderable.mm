//
//  WMRenderable.m
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/13/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "WMRenderable.h"
#import "DNEAGLContext.h"

#import "WMShader.h"

#import "WMModelPOD.h"
#import "WMTextureAsset.h"

#import "WMEngine.h"
#import "WMAssetManager.h"

NSString *WMRenderableBlendModeAdd = @"add";
NSString *WMRenderableBlendModeNormal = @"normal";

@implementation WMRenderable

@synthesize blendMode;
@synthesize hidden;
@synthesize texture;
@synthesize shader;
@synthesize model;

- (void)dealloc
{
	[shader release];
	shader = nil;
	[model release];
	model = nil;

	[texture release];
	texture = nil;


	[blendMode release];
	blendMode = nil;

	[super dealloc];
}

- (id) init {
	[super init];
	if (self == nil) return self; 
			
	return self;
}

- (id)initWithEngine:(WMEngine *)inEngine properties:(NSDictionary *)renderableRepresentation;
{
	self = [self init];
	if (!self) return nil;
	
	NSString *modelName = [renderableRepresentation objectForKey:@"model"];
	if (modelName) {
		self.model = [inEngine.assetManager modelWithName:modelName];
		if (!self.model) {
			NSLog(@"Couldn't find model %@", modelName);
			return nil;
		}
	}
	
	NSString *shaderName = [renderableRepresentation objectForKey:@"shader"];
	if (shaderName) {
		self.shader = [inEngine.assetManager shaderWithName:shaderName];
		if (!self.shader) {
			NSLog(@"Couldn't find shader %@", shaderName);
			return nil;
		}
	}
	
	NSString *textureName = [renderableRepresentation objectForKey:@"texture"];
	if (textureName) {
		self.texture = [inEngine.assetManager textureWithName:textureName];
		if (!self.texture) {
			NSLog(@"Couldn't find texture: %@", textureName);
			return nil;
		}
	}
	
	//Default = NO
	self.hidden = [[renderableRepresentation objectForKey:@"hidden"] boolValue];
	
	self.blendMode = [renderableRepresentation objectForKey:@"blendMode"];
	ZAssert([blendMode isEqualToString:WMRenderableBlendModeAdd] || [blendMode isEqualToString:WMRenderableBlendModeNormal] || !blendMode, @"Invalid blending mode");
	
	return self;
}

- (void)update;
{
	//Override this
}

- (void)drawWithTransform:(MATRIX)transform API:(EAGLRenderingAPI)API glState:(DNEAGLContext *)inGLState;
{
	if (!model) return;
	
	GL_CHECK_ERROR;
	if (API == kEAGLRenderingAPIOpenGLES2)
    {
		unsigned int attributeMask = [model dataMask];
		unsigned int shaderMask = [shader attributeMask];
		unsigned int enableMask = attributeMask & shaderMask;
		[inGLState setVertexAttributeEnableState:enableMask];
		
		[inGLState setDepthState:DNGLStateDepthTestEnabled | DNGLStateDepthWriteEnabled];
		
		if ([blendMode isEqualToString:WMRenderableBlendModeAdd]) {
			[inGLState setBlendState:DNGLStateBlendEnabled | DNGLStateBlendModeAdd];
		} else {
			[inGLState setBlendState:0];
		}
		
		glUseProgram(shader.program);
		
		size_t stride = [model interleavedDataStride];
		
		//Bind VBO, EBO
		glBindBuffer(GL_ARRAY_BUFFER, [model vbo]);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, [model ebo]);

		//Position
		glVertexAttribPointer(WMShaderAttributePosition, 3, GL_FLOAT, GL_FALSE, stride, (GLvoid *)[model positionOffset]);
		ZAssert(enableMask & WMRenderableDataAvailablePosition, @"Position issue");

		//Normal
		if (enableMask & WMRenderableDataAvailableNormal)
			glVertexAttribPointer(WMShaderAttributeNormal, 3, GL_FLOAT, GL_FALSE, stride, (GLvoid *)[model normalOffset]);

		
		//TexCoord0
		if (enableMask & WMRenderableDataAvailableTexCoord0) {
			glVertexAttribPointer(WMShaderAttributeTexCoord0, 2, GL_FLOAT, GL_FALSE, stride, (GLvoid *)[model texCoord0Offset]);
		}
		
		int textureUniformLocation = [shader uniformLocationForName:@"texture"];
		if (texture && textureUniformLocation != -1) {
			if ([texture.type isEqualToString:WMTextureAssetTypeCubeMap]) {
				glBindTexture(GL_TEXTURE_CUBE_MAP, [texture glTexture]);
			} else {
				glBindTexture(GL_TEXTURE_2D, [texture glTexture]);
			}
			glUniform1i(textureUniformLocation, 0); //texture = texture 0
		}
		
		int matrixUniform = [shader uniformLocationForName:@"modelViewProjectionMatrix"];
		if (matrixUniform != -1) {
			glUniformMatrix4fv(matrixUniform, 1, NO, transform.f);
		}
        
        // Validate program before drawing. This is a good check, but only really necessary in a debug build.
        // DEBUG macro must be defined in your debug configurations if that's not already the case.
#if defined(DEBUG)
        if (![shader validateProgram])
        {
            NSLog(@"Failed to validate program in shader: %@", shader);
            return;
        }
#endif

		GL_CHECK_ERROR;

		glDrawElements(GL_TRIANGLES, [model numberOfTriangles] * 3, [model triangleIndexType], 0);

		GL_CHECK_ERROR;

		glBindBuffer(GL_ARRAY_BUFFER, 0);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    }
    else
    {        
		//TODO: es1 support

    	//Just a test...
		glPointSize(4.f);
		glDrawArrays(GL_POINTS, 0, [model numberOfVertices]);
	}
    	
	GL_CHECK_ERROR;

}
@end
