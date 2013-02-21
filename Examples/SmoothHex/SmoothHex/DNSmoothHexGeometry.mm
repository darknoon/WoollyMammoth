//
//  DNSmoothHexGeometry.m
//  SmoothHex
//
//  Created by Andrew Pouliot on 1/29/13.
//  Copyright (c) 2013 Darknoon. All rights reserved.
//

#import "DNSmoothHexGeometry.h"

#import <WMLite/WMLite.h>

struct DNHexVertex {
	GLKVector2 p;
	//Need texture coords for all samples we want to take at this point
	GLKVector2 centers[4];
};

const WMStructureField DNHexVertex_fields[] = {
	{.name = "p",   .type = WMStructureTypeFloat, .count = 2, .normalized = NO,  .offset = offsetof(DNHexVertex, p)},
	{.name = "c0",  .type = WMStructureTypeFloat, .count = 2, .normalized = NO,  .offset = offsetof(DNHexVertex, centers[0])},
	{.name = "c1",  .type = WMStructureTypeFloat, .count = 2, .normalized = NO,  .offset = offsetof(DNHexVertex, centers[1])},
	{.name = "c2",  .type = WMStructureTypeFloat, .count = 2, .normalized = NO,  .offset = offsetof(DNHexVertex, centers[2])},
	{.name = "c3",  .type = WMStructureTypeFloat, .count = 2, .normalized = NO,  .offset = offsetof(DNHexVertex, centers[3])},
};


GLKVector2 getCoordinatePosition(int column, int row, float r) {
	int odd = row % 2;
	float columnWidth = r;
	float rowHeight = r * sqrtf(3.0f) / 2.0f;
	return GLKVector2Make(-0.5 * r + columnWidth * (column + (odd ? 0.5f : 0.0f)), rowHeight * row);
}

void generateVertices(int rows, int columns, float r, DNHexVertex *outVertices) {
	
	//Offsets are small ints
	struct IntOffset {
		char columnOffset, rowOffset;
	};
	
	//Where to find each of the centers from this point. These are multiples of the basis vectors
	//3 cases alterating horizontally
	//2 triangles per parallelogram
	//4 samples per triangle
	//This LUT is for even rows. Odd rows are transformed below
	static const struct IntOffset centerOffsetLUT[3][2][4] = {
		{//0
			{{0,0}, {1,-1}, {1,1}, {0,2}},
			{{0,0}, {1,-1}, {1,1}, {0,2}}
		},{//1
			{{-1,0}, {0,1}, {0, -1}, {2,0}},
			{{2,0}, {0,1}, {0, -1}, {2,2}}
		},{//2
			{{-1,-1}, {1,0}, {-1, 1}, {1,2}},
			{{2,1}, {1,0}, {-1, 1}, {1,2}}
		}
	};
	
	//Enumerate clockwise triangles by offset from current location
	//2 even odd
	//2 triangles
	//3 verts per triangle
	static const IntOffset triOffsetLut[2][2][3] = {
		{//even
			{{0,0}, {0,1}, {1,0}},//tri 0
			{{1,0}, {0,1}, {1,1}} //tri 1
		}, {//odd
			{{0,0}, {0,1}, {1,1}},//tri 0
			{{0,0}, {1,1}, {1,0}} //tri 1
		}
	};
	
	int outputVertexIndex = 0;
	for (int column = 0; column < columns; column++) {
		for (int row = 0; row < rows; row++) {
			//Do one parallelogram per iteration through the loop
			
			bool odd = row % 2;

			//Output 2 triangles per parellelogram
			for (int tri=0; tri<2; tri++) {
				//Calculate each vertex in the triangle
				for (int triVert = 0; triVert<3; triVert++) {
					DNHexVertex vert;
					vert.p = getCoordinatePosition(column + triOffsetLut[odd][tri][triVert].columnOffset, row + triOffsetLut[odd][tri][triVert].rowOffset , r);
					
					for (int sampleCenterIdx=0; sampleCenterIdx<4; sampleCenterIdx++) {
						IntOffset thisOffset = centerOffsetLUT[column % 3][tri][sampleCenterIdx];
						
						if (odd) {
							thisOffset.rowOffset = 1 - thisOffset.rowOffset;
						}
						
						GLKVector2 centerPosition = getCoordinatePosition(column + thisOffset.columnOffset,
																		  row    + thisOffset.rowOffset,
																		  r);
						vert.centers[sampleCenterIdx] = centerPosition;
					}
					outVertices[outputVertexIndex++] = vert;
				}
			}
		}
	}

}



@implementation DNSmoothHexGeometry

- (WMRenderObject *)generate;
{
	int columns = ceilf(self.rect.size.width / self.r + 0.5);
	float rowColumnRatio = (sqrtf(3.0f) / 3.0f);
	int rows = ceilf(self.rect.size.height / self.r / rowColumnRatio + 0.5);
	
	size_t outVertexCount = rows * columns * 2 * 3;
	DNHexVertex *verts = new DNHexVertex[outVertexCount];
	generateVertices(rows, columns, self.r, verts);
	
	WMStructureDefinition *def = [[WMStructureDefinition alloc] initWithFields:DNHexVertex_fields
																		 count:sizeof(DNHexVertex_fields)/sizeof(DNHexVertex_fields[0])
																	 totalSize:sizeof(DNHexVertex)];
	
	WMStructuredBuffer *vertexBuffer = [[WMStructuredBuffer alloc] initWithDefinition:def];
	[vertexBuffer appendData:verts withStructure:def count:outVertexCount];
	
	WMRenderObject *ro = [[WMRenderObject alloc] init];
	ro.vertexBuffer = vertexBuffer;
	
	return ro;
}


@end
