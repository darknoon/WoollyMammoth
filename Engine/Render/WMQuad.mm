//
//  WMQuad.m
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/21/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "WMQuad.h"

typedef struct WMQuadVertex {
	float v[3];
	float tc[2];
	//TODO: Align to even power boundary?
};

@implementation WMQuad

- (id)init;
{
	self = [super init];
	if (!self) return nil;
	
	glGenBuffers(1, &vbo);
	glGenBuffers(1, &ebo);
	
	void *vertexData;
	unsigned short *indexData;

	vertexData = malloc(sizeof(WMQuadVertex) * 4);
	if (!vertexData) {
		[self release];
		return nil;
	}
	
	const float scale = 1;
	
	//Add vertices
	WMQuadVertex *vertexDataPtr = (WMQuadVertex *)vertexData;
	for (int y=0, i=0; y<2; y++) {
		for (int x=0; x<2; x++, i++) {
			
			vertexDataPtr[i].v[0] = ((float)x - 0.5f) * 2.0f * scale;
			vertexDataPtr[i].v[1] = ((float)y - 0.5f) * 2.0f * scale;
			vertexDataPtr[i].v[2] = 0.0f;
			
			vertexDataPtr[i].tc[0] = (float)x;
			vertexDataPtr[i].tc[1] = (float)y;
		}
	}
		
	indexData = (unsigned short *)malloc(sizeof(indexData[0]) * 2 * 3); 
	if (!indexData) {
		[self release];
		return nil;
	}
	//Add triangles
	indexData[0] = 0;
	indexData[1] = 1;
	indexData[2] = 2;

	indexData[3] = 1;
	indexData[4] = 2;
	indexData[5] = 3;
	
	glBindBuffer(GL_ARRAY_BUFFER, vbo);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);
	
	glBufferData(GL_ARRAY_BUFFER, sizeof(WMQuadVertex) * 4, vertexData, GL_STATIC_DRAW);
	GL_CHECK_ERROR;
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, 6 * sizeof (unsigned short), indexData, GL_STATIC_DRAW);
	
	GL_CHECK_ERROR;
	
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
	
	
	if (vertexData) free(vertexData);
	if (indexData) free(indexData);

	
	return self;
}

- (void) dealloc
{	
	if (vbo) glDeleteBuffers(1, &vbo);
	if (ebo) glDeleteBuffers(1, &ebo);
	[super dealloc];
}

- (unsigned int)dataMask;
{
	return WMRenderableDataAvailablePosition | WMRenderableDataAvailableTexCoord0 | WMRenderableDataAvailableIndexBuffer;
}

- (GLuint)vbo;
{
	return vbo;
}

- (GLenum)ebo; //element buffer object
{
	return ebo;
}



- (int)positionOffset;
{
	return 0;
}

- (int)colorOffset;
{
	ZAssert(0, @"No color component of quad");
	return 0;
}
- (int)texCoord0Offset;
{
	return 3 * sizeof(float);
}

- (int)normalOffset;
{
	ZAssert(0, @"No normal component of quad");
	return 0;
}

- (size_t)interleavedDataStride;
{
	return sizeof(WMQuadVertex);
}
- (size_t)numberOfTriangles;
{
	return 2;
}
- (size_t)numberOfVertices;
{
	return 4;
}

- (GLenum)triangleIndexType;
{
	return GL_UNSIGNED_SHORT;
}



@end
