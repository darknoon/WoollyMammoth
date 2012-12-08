//
//  DNPCPostProcess.m
//  ParticleCascade
//
//  Created by Andrew Pouliot on 9/20/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import "DNPCPostProcess.h"

#import <WMLite/WMLite.h>

@implementation DNPCPostProcess {
	WMRenderObject *_quad;
	WMStructureDefinition *_structure;
}

- (id)init;
{
    self = [super init];
    if (!self) return nil;
	
	_quad = [WMRenderObject quadRenderObjectWithFrame:(CGRect){{-1, -1}, {2, 2}}];
	
	NSError *error = nil;
	NSString *shaderName = @"PostProcess";
	NSString *path = [[NSBundle mainBundle] pathForResource:shaderName ofType:@"glsl"];
	NSString *shaderText = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
	
	WMShader *shader = [[WMShader alloc] initWithVertexShader:shaderText fragmentShader:shaderText error:&error];

	if (!shader) return nil;
	
	_quad.shader = shader;
	
    return self;
}


- (void)processTexture:(WMTexture2D *)texture renderToFramebuffer:(WMFramebuffer *)outputFramebuffer;
{
	if (!texture) return;
	
	WMEAGLContext *context = (WMEAGLContext *)[WMEAGLContext currentContext];
	[context renderToFramebuffer:outputFramebuffer block:^{
		[context clearToColor:(GLKVector4){0, 0, 0, 1}];

		[_quad setValue:texture forUniformWithName:@"sTexture"];
		[context renderObject:_quad];
	}];
	
	//Clear texture so we don't retain it
	[_quad setValue:nil forUniformWithName:@"sTexture"];
	
}

@end
