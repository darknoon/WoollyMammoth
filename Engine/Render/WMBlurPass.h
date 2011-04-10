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
@class DNEAGLContext;
@class WMShader;
@class DNFramebuffer;
@class Texture2D;

#define WMBlurPass_NBlurTextures 2

@interface WMBlurPass : NSObject {	
	DNFramebuffer *framebuffer;
	Texture2D *blurTextures[WMBlurPass_NBlurTextures];
	
	Texture2D *outputTexture;
	
	WMShader *blurShader;
}

- (Texture2D *)doBlurPassFromInputTexture:(GLuint)inputTexture textureWidth:(int)inTextureWidth textureHeight:(int)inTextureHeight withGLState:(DNEAGLContext *)inGLState;

@end
