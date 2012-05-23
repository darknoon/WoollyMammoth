//
//  WMWireframe.m
//  WMEdit
//
//  Created by Andrew Pouliot on 10/28/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import "WMWireframe.h"

#import "WMRenderObject.h"

@implementation WMWireframe
@synthesize inputObject;
@synthesize outputObject;

- (BOOL)execute:(WMEAGLContext *)context time:(double)time arguments:(NSDictionary *)args;
{
	//Get in the vertex buffer and index buffer from the input object, output a render object that renders triangles in a blue outline
	
	//TODO: use render object copying here to copy the vertex shader params
	WMRenderObject *roIn = inputObject.object;
	if (roIn) {
		WMRenderObject *roOut = [[WMRenderObject alloc] init];
		
		roOut.vertexBuffer = roIn.vertexBuffer;
		roOut.indexBuffer = roIn.indexBuffer;
		
		WMStructureDefinition *def = [[WMStructureDefinition alloc] initWithAnonymousFieldOfType:WMStructureTypeUnsignedInt];
		WMStructuredBuffer *outlineIndexBuf = [[WMStructuredBuffer alloc] initWithDefinition:def];
		
		//Read the points from the indexBuffer
		if (roIn.indexBuffer.definition.isSingleType) {
			
		} else {
			return NO;
		}
		
		roOut.renderType = GL_LINES;
		
		outputObject.object = roOut;
	} else {
		outputObject.object = nil;
	}
	
	return YES;
}


@end
