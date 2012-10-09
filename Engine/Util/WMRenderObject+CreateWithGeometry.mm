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


typedef struct {
	float v[4];
	unsigned char tc[2];
} WMQuadVertex;

static WMStructureField WMQuadVertex_fields[] = {
	{.name = "position",  .type = WMStructureTypeFloat,        .count = 3, .normalized = NO,  .offset = offsetof(WMQuadVertex, v)},
	{.name = "texCoord0", .type = WMStructureTypeUnsignedByte, .count = 2, .normalized = YES, .offset = offsetof(WMQuadVertex, tc)},
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
			.tc = {255, 0}
		},
		{
			.v = {CGRectGetMinX(inFrame), CGRectGetMaxY(inFrame), 0, 1}, 
			.tc = {0, 255}
		},
		{
			.v = {CGRectGetMaxX(inFrame), CGRectGetMaxY(inFrame), 0, 1}, 
			.tc = {255, 255}
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


@end
