//
//  WMBlurPass.m
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 12/26/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "WMBlurPass.h"

#import "WMEngine.h"
#import "WMEAGLContext.h"
#import "WMShader.h"

#import "Vector.h"

#import "WMTexture2D.h"
#import "WMFramebuffer.h"

typedef struct {
	Vec3 p;
	Vec2 tc;
} WMBlurPassVertex;

@implementation WMBlurPass

- (id)init;
{
	self = [super init];
	
	if (!self) return nil;

	const CGSize textureSize = {320, 480};
	for (int i=0; i<WMBlurPass_NBlurTextures; i++) {
		blurTextures[i] = [[WMTexture2D alloc] initWithData:NULL
											  pixelFormat:kWMTexture2DPixelFormat_RGBA8888
											   pixelsWide:textureSize.width
											   pixelsHigh:textureSize.height
											  contentSize:textureSize];
	}
	
	outputTexture = blurTextures[1];
	
	framebuffer = [[WMFramebuffer alloc] initWithTexture:outputTexture depthBufferDepth:0];
	

	return self;
	
}

- (void)dealloc {
    [framebuffer release];
	
    [super dealloc];
}


- (WMTexture2D *)doBlurPassFromInputTexture:(GLuint)inputTexture textureWidth:(int)inTextureWidth textureHeight:(int)inTextureHeight withGLState:(WMEAGLContext *)inGLState;
{
	if (!blurShader) {
		NSArray *uniformNames = [NSArray arrayWithObjects:@"texture", @"invStepWidth1", @"invStepWidth2", nil];
		NSDictionary *dict = [NSDictionary dictionaryWithObject:uniformNames forKey:@"uniformNames"];
		
		NSString *blurFrag = [[NSBundle mainBundle] pathForResource:@"WMGaussianBlur" ofType:@"fsh"];
		NSString *blurVert = [[NSBundle mainBundle] pathForResource:@"WMGaussianBlur" ofType:@"vsh"];
		
		blurShader = [[WMShader alloc] initWithVertexShader:blurVert pixelShader:blurFrag];
	}
			
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
	
	
	return outputTexture;
}

- (GLuint)glTexture;
{
	return outputTexture.name;
}

@end
