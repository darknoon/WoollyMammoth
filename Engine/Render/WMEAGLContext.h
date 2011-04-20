//
//  DNGLState.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 12/8/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMShader.h"

enum {
	WMRenderableDataAvailablePosition    = 1 << WMShaderAttributePosition,
	WMRenderableDataAvailablePosition2d  = 1 << WMShaderAttributePosition2d,
	WMRenderableDataAvailableNormal      = 1 << WMShaderAttributeNormal,
	WMRenderableDataAvailableColor       = 1 << WMShaderAttributeColor,
	WMRenderableDataAvailableTexCoord0   = 1 << WMShaderAttributeTexCoord0,
	WMRenderableDataAvailableTexCoord1   = 1 << WMShaderAttributeTexCoord1,
	WMRenderableDataAvailableIndexBuffer = 1 << (WMShaderAttributeCount + 0),
};
typedef int WMRenderableDataMask;

enum {
	DNGLStateBlendEnabled = 1 << 0,
	DNGLStateBlendModeAdd = 1 << 1, //otherwise blend is source-over
} ;
typedef int DNGLStateBlendMask;

enum {
	DNGLStateDepthTestEnabled  = 1 << 0,
	DNGLStateDepthWriteEnabled = 1 << 1,
};
typedef int DNGLStateDepthMask;

@class DNFramebuffer;

@interface WMEAGLContext : EAGLContext {
	//Uses constants from WMShader.h
	WMRenderableDataMask vertexAttributeEnableState;
	DNGLStateBlendMask blendState;
	DNGLStateDepthMask depthState;
	DNFramebuffer *boundFramebuffer;
}

- (void)setVertexAttributeEnableState:(int)vertexAttributeEnableState;

@property (nonatomic) DNGLStateBlendMask blendState;
@property (nonatomic) DNGLStateDepthMask depthState;
@property (nonatomic, retain) DNFramebuffer *boundFramebuffer;

@end
