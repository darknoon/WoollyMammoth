//
//  WMSetShader.h
//  WMEdit
//
//  Created by Andrew Pouliot on 7/27/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMPatch.h"

@class WMShader;
@interface WMSetShader : WMPatch {
	BOOL shaderDirty;
	WMShader *shader;
	//Ports will be added for any uniforms present in the shader
	WMRenderObjectPort *inputObject;
	WMRenderObjectPort *outputObject;
}

@property (nonatomic, readonly) BOOL shaderIsCompiled;
@property (nonatomic, copy, readonly) NSString *shaderCompileLog;

@property (nonatomic, copy) NSString *vertexShader;
@property (nonatomic, copy) NSString *fragmentShader;
	
@end
