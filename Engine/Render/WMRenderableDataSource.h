//
//  WMRenderableDataSource.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/21/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMRenderCommon.h"
#import "DNGLState.h"

@protocol WMRenderableDataSource

- (unsigned int)dataMask;

- (GLuint)vbo;

//-1 == not applicable
- (int)positionOffset;
- (int)colorOffset;
- (int)texCoord0Offset;
- (int)normalOffset;

- (size_t)interleavedDataStride;
- (size_t)numberOfVertices;

- (GLenum)ebo; //element buffer object
- (size_t)numberOfTriangles;
- (GLenum)triangleIndexType;


@end
