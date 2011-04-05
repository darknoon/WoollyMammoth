//
//  DNGLState.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 12/8/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMShader.h"

typedef enum {
	WMRenderableDataAvailablePosition    = 1 << WMShaderAttributePosition,
	WMRenderableDataAvailableNormal      = 1 << WMShaderAttributeNormal,
	WMRenderableDataAvailableColor       = 1 << WMShaderAttributeColor,
	WMRenderableDataAvailableTexCoord0   = 1 << WMShaderAttributeTexCoord0,
	WMRenderableDataAvailableTexCoord1   = 1 << WMShaderAttributeTexCoord1,
	WMRenderableDataAvailableIndexBuffer = 1 << (WMShaderAttributeCount + 0),
}  WMRenderableDataMask;

typedef enum {
	DNGLStateBlendEnabled = 1 << 0,
	DNGLStateBlendModeAdd = 1 << 1, //otherwise blend is source-over
} DNGLStateBlendMask;

typedef enum {
	DNGLStateDepthTestEnabled  = 1 << 0,
	DNGLStateDepthWriteEnabled = 1 << 1,
} DNGLStateDepthMask;

@interface DNGLState : NSObject {
	//Uses constants from WMShader.h
	WMRenderableDataMask vertexAttributeEnableState;
	DNGLStateBlendMask blendState;
	DNGLStateDepthMask depthState;
}

- (void)setVertexAttributeEnableState:(int)vertexAttributeEnableState;

- (void)setBlendState:(int)inBlendState;

- (void)setDepthState:(int)inDepthState;

@end
