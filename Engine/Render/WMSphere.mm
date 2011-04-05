//
//  WMSphere.m
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 12/6/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "WMSphere.h"

#import "Vector.h"

//Position, Normal, Color, TexCoord0, TexCoord1, PointSize, Weight, MatrixIndex
struct WMSphereVertex {
	Vec3 v;
	Vec3 n;
	Vec2 tc;
	//TODO: Align to even 32-byte boundary?
};

@implementation WMSphere

- (id)init;
{
	GL_CHECK_ERROR;

	self = [super init];
	if (!self) return nil;

	
	WMSphereVertex *vertexData;
	unsigned short *indexData;

	unum = 50;
	vnum = 50;
	
	radius = 0.535f;
	
	glGenBuffers(1, &vbo);
	glGenBuffers(1, &ebo);
	
	vertexData = new WMSphereVertex[unum * vnum];
	if (!vertexData) {
		[self release];
		NSLog(@"Out of mem");
		return nil;
	}
	indexData = new unsigned short [unum * (vnum - 1) * 2 * 3]; 
	if (!indexData) {
		[self release];
		NSLog(@"Out of mem");
		return nil;
	}
	
	Vec3 spherePosition = Vec3(0.0f, 0.045f, 0.0f);
	
	//Add vertices
	for (int u=0, i=0, indexDataIndex=0; u<unum; u++) {
		for (int v=0; v<vnum; v++, i++) {
			float theta = u * 2.0f * M_PI / unum;
			float phi = v * M_PI / vnum;
			//Add the vertex
			vertexData[i].n = Vec3(sinf(phi)*cosf(theta),
								   sinf(phi)*sinf(theta), 
								   cosf(phi));
			vertexData[i].v = radius * vertexData[i].n + spherePosition;
			vertexData[i].tc = Vec2(theta, phi);
			
			//Add the triangles in the quad {(u,v), (u+1,v), (u,v+1), (u+1,v+1)}
			unsigned short nextU = (u+1) % unum;
			unsigned short nextV = v+1;
			
			if (nextV < vnum) {	//Don't add last row
				indexData[indexDataIndex++] = u * vnum + v;
				indexData[indexDataIndex++] = nextU * vnum + v;
				indexData[indexDataIndex++] = u * vnum + nextV;

				indexData[indexDataIndex++] = nextU * vnum + v;
				indexData[indexDataIndex++] = u * vnum + nextV;
				indexData[indexDataIndex++] = nextU * vnum + nextV;
			}
		}
	}
	
#if DEBUG
	int maxRefI = 0;
	for (int i=0; i<[self numberOfTriangles]*3; i++) {
		maxRefI = MAX(maxRefI, indexData[i]);
	}
	ZAssert(maxRefI < unum * vnum, @"Bad tri index!");
#endif
	
	glBindBuffer(GL_ARRAY_BUFFER, vbo);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo);

	glBufferData(GL_ARRAY_BUFFER, unum * vnum * sizeof(WMSphereVertex), vertexData, GL_STATIC_DRAW);
	GL_CHECK_ERROR;
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, unum * (vnum - 1) * 2 * 3 * sizeof (unsigned short), indexData, GL_STATIC_DRAW);

	GL_CHECK_ERROR;
	
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
	
	if (vertexData) delete vertexData;
	if (indexData) delete indexData;

	return self;
}

- (void)dealloc;
{
	if (vbo) glDeleteBuffers(1, &vbo);
	if (ebo) glDeleteBuffers(1, &ebo);
	
	[super dealloc];
}

- (unsigned int)dataMask;
{
	return WMRenderableDataAvailablePosition | WMRenderableDataAvailableNormal | WMRenderableDataAvailableTexCoord0 | WMRenderableDataAvailableIndexBuffer;
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
	ZAssert(0, @"No coor component of sphere");
	return 0;
}
- (int)texCoord0Offset;
{
	return 2 * sizeof(Vec3);
}

- (int)normalOffset;
{
	return sizeof(Vec3);
}

- (size_t)interleavedDataStride;
{
	return sizeof(WMSphereVertex);
}
- (size_t)numberOfTriangles;
{
	return unum * (vnum - 1) * 2;
}
- (size_t)numberOfVertices;
{
	return unum * vnum;
}

- (GLenum)triangleIndexType;
{
	return GL_UNSIGNED_SHORT;
}


@end
