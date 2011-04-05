//
//  WMModelPOD.m
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/15/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "WMModelPOD.h"

#import "WMRenderCommon.h"


@implementation WMModelPOD

@synthesize scale;

- (id)initWithResourceName:(NSString *)inResourceName properties:(NSDictionary *)inProperties assetManager:(WMAssetManager *)inAssetManager;
{
	[super initWithResourceName:inResourceName properties:inProperties  assetManager:inAssetManager];
	if (self == nil) return self; 
	
	scale = 1.0f;
	if ([properties objectForKey:@"scale"]) {
		scale = [[properties objectForKey:@"scale"] floatValue];
	}
	
	return self;
}

- (void) dealloc
{
	delete podmodel;
	//TODO: delete mesh…
	

	[super dealloc];
}


- (BOOL)loadWithBundle:(NSBundle *)inBundle error:(NSError **)outError;
{
	if (!isLoaded) {
		
		podmodel = new CPVRTModelPOD();
		
		NSString *relativePath = [resourceName stringByAppendingPathExtension:@"pod"];
		[self requireAssetFileSynchronous:relativePath];
		
		NSString *podPath = [[inBundle bundlePath] stringByAppendingPathComponent:relativePath];
		
		
		podmodel->ReadFromFile([podPath UTF8String], NULL, 1);
		
		mesh = podmodel->pMesh[0];
		
		//Make sure mesh is interleaved
		if (!mesh.pInterleaved) {
			//TODO: make error type
			NSLog(@"Mesh not interleaved! Please re-export this POD file: %@", podPath);
			delete podmodel;
			return NO;
		}
		
		//Log vertices
		void *data = [self vertexDataPointer];
		for (int i=0; i<[self numberOfVertices]; i++) {
			float *v = (float *)( (int)data + i * [self interleavedDataStride] );
			v[0] *= scale;
			v[1] *= scale;
			v[2] *= scale;			
		}
		
		isLoaded = YES;
	} else {
		NSLog(@"Tried to load model when already loaded");
	}

	return YES;
}

- (size_t)interleavedDataStride;
{
	return mesh.sVertex.nStride;
}

- (void *)vertexDataPointer;
{
	//Yay, pointer arithmatic
	return (void *)((int)mesh.pInterleaved + (int)mesh.sVertex.pData);
}

- (void *)textureCoordDataPointer;
{
	//TODO: support this
	return NULL;
}

- (void *)normalCoordDataPointer;
{
	//Yay, pointer arithmatic
	return (void *)((int)mesh.pInterleaved + (int)mesh.sNormals.pData);
}

- (void *)interleavedDataPointer;
{
	return mesh.pInterleaved;
}

- (size_t)numberOfTriangles;
{
	return mesh.nNumFaces;
}

- (size_t)numberOfVertices;
{
	return mesh.nNumVertex;
}

- (GLenum)triangleIndexType;
{
	switch (mesh.sFaces.eType) {
		case EPODDataInt:
			return GL_INT;
		case EPODDataUnsignedShort:
			return GL_UNSIGNED_SHORT;
		case EPODDataUnsignedByte:
			return GL_UNSIGNED_BYTE;
		default:
			NSLog(@"Unknown triangle index type: %d", mesh.sFaces.eType);
			return GL_UNSIGNED_SHORT;
	}
}

- (unsigned short *)triangleIndexPointer;
{
	return (unsigned short *)mesh.sFaces.pData;
}

@end
