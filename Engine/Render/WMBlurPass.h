//
//  WMBlurPass.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 12/26/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMTextureAsset.h"

//Act as a texture asset for now to input into blah
@class DNGLState;
@class WMShader;

#define WMBlurPass_NBlurTextures 2

@interface WMBlurPass : WMTextureAsset {	
	GLuint framebuffer;
	GLuint blurTextures[WMBlurPass_NBlurTextures];
	
	int outputBlurTexture;
	
	WMShader *blurShader;
}


- (void)doBlurPassFromInputTexture:(GLuint)inputTexture textureWidth:(int)inTextureWidth textureHeight:(int)inTextureHeight withGLState:(DNGLState *)inGLState;

@end
