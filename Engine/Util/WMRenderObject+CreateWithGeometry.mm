//
//  WMRenderObject+CreateWithGeometry.m
//  DadaBubble
//
//  Created by Andrew Pouliot on 11/19/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import "WMRenderObject+CreateWithGeometry.h"
#import "WMStructureDefinition.h"
#import "WMStructuredBuffer.h"
#import "WMTexture2D.h"


struct WMQuadVertex {
	GLKVector4 v;
	GLKVector2 tc;
};

static WMStructureField WMQuadVertex_fields[] = {
	{.name = "position",  .type = WMStructureTypeFloat, .count = 4, .normalized = NO,  .offset = offsetof(WMQuadVertex, v)},
	{.name = "texCoord0", .type = WMStructureTypeFloat, .count = 2, .normalized = NO, .offset = offsetof(WMQuadVertex, tc)},
};


@implementation WMRenderObject (CreateWithGeometry)

+ (WMRenderObject *)quadRenderObjectWithFrame:(CGRect)inFrame;
{
	WMRenderObject *ro = [[WMRenderObject alloc] init];
	
	WMStructureDefinition *vertexDef = [[WMStructureDefinition alloc] initWithFields:WMQuadVertex_fields count:2 totalSize:sizeof(WMQuadVertex)];
	WMStructuredBuffer *vertexBuffer = [[WMStructuredBuffer alloc] initWithDefinition:vertexDef];
	
	//Add vertices
	WMQuadVertex vertexDataPtr[4] = {
		{
			.v = {CGRectGetMinX(inFrame), CGRectGetMinY(inFrame), 0, 1}, 
			.tc = {0, 0}
		},
		{
			.v = {CGRectGetMaxX(inFrame), CGRectGetMinY(inFrame), 0, 1}, 
			.tc = {1, 0}
		},
		{
			.v = {CGRectGetMinX(inFrame), CGRectGetMaxY(inFrame), 0, 1}, 
			.tc = {0, 1}
		},
		{
			.v = {CGRectGetMaxX(inFrame), CGRectGetMaxY(inFrame), 0, 1}, 
			.tc = {1, 1}
		}};	
	
	[vertexBuffer appendData:vertexDataPtr withStructure:vertexBuffer.definition count:4];
	
	
	WMStructureDefinition *indexDef = [[WMStructureDefinition alloc] initWithAnonymousFieldOfType:WMStructureTypeUnsignedShort];
	WMStructuredBuffer *indexBuffer = [[WMStructuredBuffer alloc] initWithDefinition:indexDef];
	
	//Add triangles
	unsigned short indexData[2 * 3] = {0,1,2, 1,2,3};
	[indexBuffer appendData:indexData withStructure:indexBuffer.definition count:2 * 3];
	
	ro.vertexBuffer = vertexBuffer;
	ro.indexBuffer = indexBuffer;
	return ro;
}

+ (WMRenderObject *)quadRenderObjectWithTexture2D:(WMTexture2D *)inImage uSubdivisions:(NSUInteger)uCount vSubdivisions:(NSUInteger)vCount;
{
	//Scale width to 1
	
	const CGFloat aspectRatio = inImage.contentSize.height / inImage.contentSize.width;
	
	GLKVector3 basisU;
	GLKVector3 basisV;
	
	
	//If fitU, then scale the image to fit based on its U/width dimension. Otherwise use its V/height dimension.
	
	switch (inImage.orientation) {
		default:
		case UIImageOrientationUp:
			basisU = (GLKVector3){1.0f, 0.0f, 0.0f};
			basisV = (GLKVector3){0.0f, 1.0f * aspectRatio, 0.0f};
			break;
		case UIImageOrientationUpMirrored:
			basisU = (GLKVector3){1.0f, 0.0f, 0.0f};
			basisV = (GLKVector3){0.0f, -1.0f * aspectRatio, 0.0f};
			break;
		case UIImageOrientationDown:
			basisU = (GLKVector3){-1.0f, 0.0f, 0.0f};
			basisV = (GLKVector3){0.0f, -1.0f * aspectRatio, 0.0f};
			break;
		case UIImageOrientationDownMirrored:
			basisU = (GLKVector3){-1.0f, 0.0f, 0.0f};
			basisV = (GLKVector3){0.0f, 1.0f * aspectRatio, 0.0f};
			break;
		case UIImageOrientationLeft:
			basisU = (GLKVector3){0.0f, -1.0f / aspectRatio, 0.0f};
			basisV = (GLKVector3){1.0f, 0.0f, 0.0f};
			break;
		case UIImageOrientationLeftMirrored:
			basisU = (GLKVector3){0.0f, 1.0f / aspectRatio, 0.0f};
			basisV = (GLKVector3){1.0f, 0.0f, 0.0f};
			break;
		case UIImageOrientationRight:
			basisU = (GLKVector3){0.0f, 1.0f / aspectRatio, 0.0f};
			basisV = (GLKVector3){-1.0f, 0.0f, 0.0f};
			break;
		case UIImageOrientationRightMirrored:
			basisU = (GLKVector3){0.0f, 1.0f / aspectRatio, 0.0f};
			basisV = (GLKVector3){1.0f, 0.0f, 0.0f};
			break;
	}
	
	WMStructureDefinition *vertexDef = [[WMStructureDefinition alloc] initWithFields:WMQuadVertex_fields count:2 totalSize:sizeof(WMQuadVertex)];
	WMStructuredBuffer *vertexBuffer = [[WMStructuredBuffer alloc] initWithDefinition:vertexDef];
	
	//Add vertices
	for (int v=0, i=0; v<vCount; v++) {
		for (int u=0; u<uCount; u++, i++) {
			
			float uf = (float)u / (uCount - 1);
			float vf = (float)v / (vCount - 1);
			
			GLKVector3 point = (uf - 0.5f) * 2.0f * basisU + (vf - 0.5f) * 2.0f * basisV;
			
			const WMQuadVertex vertex = {
				.v = GLKVector4MakeWithVector3(point, 1.0f),
				.tc = {uf, 1.0 - vf} //Flip y coord to account for differing coord systems
			};
			
			//Append to vertex buffer
			[vertexBuffer appendData:&vertex withStructure:vertexDef count:1];
		}
	}
	
	//Create index data
	WMStructureDefinition *indexDef  = [[WMStructureDefinition alloc] initWithAnonymousFieldOfType:WMStructureTypeUnsignedShort];
	WMStructuredBuffer *indexBuffer = [[WMStructuredBuffer alloc] initWithDefinition:indexDef];
	for (int v=0; v<vCount-1; v++) {
		for (int u=0; u<uCount-1; u++) {
			const int i = u + v * uCount;
			const int next_i = i + uCount; //Next row
			const unsigned short twoTris[] = {
				i + 0, i + 1,       next_i + 0,
				i + 1, next_i + 0 , next_i + 1};
			[indexBuffer appendData:twoTris withStructure:indexDef count:6];
		}
	}
	
	WMRenderObject *ro = [[WMRenderObject alloc] init];
	[ro premultiplyTransform:GLKMatrix4Identity];
	ro.vertexBuffer = vertexBuffer;
	ro.indexBuffer = indexBuffer;
	ro.shader = [WMShader defaultShader];
	
	return ro;
}

@end
