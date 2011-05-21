//
//  WMBlurPass.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 12/26/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMEAGLContext.h"

//Act as a texture asset for now to input into blah
@class WMEAGLContext;
@class WMShader;
@class WMFramebuffer;
@class WMTexture2D;

#define WMBlurPass_NBlurTextures 2

@interface WMBlurPass : NSObject {	
	WMFramebuffer *framebuffer;
	WMTexture2D *blurTextures[WMBlurPass_NBlurTextures];
	
	WMTexture2D *outputTexture;
	
	WMShader *blurShader;
}

- (WMTexture2D *)doBlurPassFromInputTexture:(GLuint)inputTexture textureWidth:(int)inTextureWidth textureHeight:(int)inTextureHeight withGLState:(WMEAGLContext *)inGLState;

@end
