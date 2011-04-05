//
//  WMBlurPass.m
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 12/26/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "WMBlurPass.h"

#import "WMAssetManager.h"
#import "WMEngine.h"
#import "DNGLState.h"
#import "WMShader.h"
#import "WMRenderEngine.h"

#import "Vector.h"


typedef struct {
	Vec3 p;
	Vec2 tc;
} WMBlurPassVertex;

@implementation WMBlurPass


- (id)initWithResourceName:(NSString *)inResourceName properties:(NSDictionary *)inProperties assetManager:(WMAssetManager *)inAssetManager;
{
	self = [super initWithResourceName:inResourceName properties:inProperties assetManager:inAssetManager];
	if (!self) return nil;
		
	
	return self;
}

- (BOOL)loadWithBundle:(NSBundle *)inBundle error:(NSError **)outError;
{
	
	glGenFramebuffers(1, &framebuffer);
	glGenTextures(2, blurTextures);

	glBindTexture(GL_TEXTURE_2D, blurTextures[0]);
	int width = 1024;
	int height = 1024;
	//Fill blur texture with red
	unsigned char *buffer = new unsigned char[4 * width * height];
	for (int y=0, i=0; y<height; y++) {
		for (int x=0; x<width; x++, i++) {
			//Set to medium grey for kicks
			buffer[4*i + 0] = 255;
			buffer[4*i + 1] = 51;
			buffer[4*i + 2] = 51;
			buffer[4*i + 3] = 255;
		}
	}
	
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 1024, 1024, 0, GL_BGRA, GL_UNSIGNED_BYTE, buffer);
	
	delete buffer;
	
	//TODO: error checking
	isLoaded = YES;
	
	return YES;
}


- (void)doBlurPassFromInputTexture:(GLuint)inputTexture textureWidth:(int)inTextureWidth textureHeight:(int)inTextureHeight withGLState:(DNGLState *)inGLState;
{
	if (!blurShader) {
		blurShader = [assetManager shaderWithName:@"WMGaussianBlur"];
	}
	
	//TODO optimize out!
	
	GLint oldFrameBuffer;
	glGetIntegerv(GL_FRAMEBUFFER_BINDING, &oldFrameBuffer);
	
	glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, blurTextures[0], 0);
	
	[inGLState setBlendState:0];
	[inGLState setDepthState:0];
	[inGLState setVertexAttributeEnableState:WMRenderableDataAvailablePosition | WMRenderableDataAvailableTexCoord0];
	
	//first attempt: naive, use full resolution textures :o
	glUseProgram(blurShader.program);

	GLuint uniform1 = [blurShader uniformLocationForName:@"invStepWidth1"];
	GLuint uniform2 = [blurShader uniformLocationForName:@"invStepWidth2"];
	
	ZAssert(uniform1 != -1 && uniform2 != -1, @"WMGaussianBlur shader doesn't match code");
	
	//TODO: check width == height
	
	if (uniform1 != -1 && uniform2 != -1) {
		//Set the uniforms for correct blurring
		glUniform1f(uniform1, 1.3846153846 / inTextureWidth);
		glUniform1f(uniform2, 3.2307692308 / inTextureWidth);
	}
		
	//Do first pass
	WMBlurPassVertex quad[4];
	quad[0].p = Vec3(0.0f);
	quad[0].tc = Vec2(0.0f);

	quad[1].p = Vec3(0.0f, 1.0f, 0.0f);
	quad[1].tc = Vec2(0.0f, 1.0f);
	
	quad[2].p = Vec3(1.0f, 0.0f, 0.0f);
	quad[2].tc = Vec2(1.0f, 0.0f);

	quad[3].p = Vec3(1.0f, 1.0f, 0.0f);
	quad[3].tc = Vec2(1.0f, 1.0f);
	
	//TODO: restructure quad rendering!
	glVertexAttribPointer(WMShaderAttributePosition, 3, GL_FLOAT, GL_FALSE, sizeof(WMBlurPassVertex), &quad[0].p);
	glVertexAttribPointer(WMShaderAttributeTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(WMBlurPassVertex), &quad[0].tc);
	

	unsigned short indices[6] = {0,1,2, 1,2,3};
	
	{ // DO a render pass
		glBindTexture(GL_TEXTURE_2D, inputTexture);
		glUniform1i([blurShader uniformLocationForName:@"texture"], 0);
		
		//Render
		glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, indices);
	}
	
	glBindFramebuffer(GL_FRAMEBUFFER, oldFrameBuffer);

}

- (GLuint)glTexture;
{
	return blurTextures[0];
}

@end
