//
//  WMSphere.m
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 12/6/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "WMSphere.h"

#import "WMStructuredBuffer.h"
#import "WMShader.h"
#import "WMRenderObject.h"

//Position, Normal, Color, TexCoord0, TexCoord1, PointSize, Weight, MatrixIndex
struct WMSphereVertex {
	GLKVector3 p;
	GLKVector3 n;
	GLKVector2 tc;
};

static WMStructureField WMQuadVertex_fields[] = {
	{.name = "position",  .type = WMStructureTypeFloat,  .count = 3, .normalized = NO,  .offset = offsetof(WMSphereVertex, p)},
	{.name = "normal",    .type = WMStructureTypeFloat,  .count = 3, .normalized = NO,  .offset = offsetof(WMSphereVertex, n)},
	{.name = "texCoord0", .type = WMStructureTypeFloat,  .count = 2, .normalized = NO,  .offset = offsetof(WMSphereVertex, tc)},
};
@interface WMSphere ()
- (BOOL)loadDefaultShader;
@end

@implementation WMSphere {
	//Cached values, correspond to current value
	//TODO: use conditional execution instead?
	float radius;
	
	int unum;
	int vnum;
	
	WMShader *shader;
}


+ (NSString *)category;
{
    return WMPatchCategoryGeometry;
}

+ (NSString *)humanReadableTitle {
    return @"Sphere";
}

+ (void)load;
{
	@autoreleasepool {
		[self registerPatchClass];
	}
}

- (id)init;
{
	self = [super init];
	if (!self) return nil;
	
	return self;
}

+ (id)defaultValueForInputPortKey:(NSString *)inKey;
{
	if ([inKey isEqualToString:KVC([WMSphere new], inputUCount)]) {
		return [NSNumber numberWithInt:5];
	} else if ([inKey isEqualToString:KVC([WMSphere new], inputVCount)]) {
		return [NSNumber numberWithInt:5];
	} else if ([inKey isEqualToString:KVC([WMSphere new], inputRadius)]) {
		return [NSNumber numberWithFloat:1.0f];
	}
	return nil;
}

- (BOOL)setup:(WMEAGLContext *)context;
{
	[self loadDefaultShader];
	
	return shader != nil;
}

- (void)cleanup:(WMEAGLContext *)context;
{
}

- (BOOL)loadDefaultShader;
{
	//TODO: make a better system for default shaders!
	NSError *defaultShaderError = nil;
	NSString *vertexShader = [NSString stringWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"WMDefaultShader" withExtension:@"vsh"] encoding:NSASCIIStringEncoding error:&defaultShaderError];
	if (defaultShaderError) {
		NSLog(@"Error loading default vertex shader: %@", defaultShaderError);
		return NO;
	}
	
	NSString *fragmentShader = [NSString stringWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"WMDefaultShader" withExtension:@"fsh"] encoding:NSASCIIStringEncoding error:&defaultShaderError];
	if (defaultShaderError) {
		NSLog(@"Error loading default fragment shader: %@", defaultShaderError);
		return NO;
	}
	
	shader = [[WMShader alloc] initWithVertexShader:vertexShader fragmentShader:fragmentShader error:&defaultShaderError];
	if (defaultShaderError) {
		NSLog(@"Error loading default shader: %@", defaultShaderError);
		return NO;
	}
	
	return YES;
}

- (BOOL)recreateVertexData;
{
	
	unum = _inputUCount.index;
	vnum = _inputVCount.index;
	radius = _inputRadius.value;
	
	const int numberOfVertices = unum * vnum;
	const int numberOfTriangles = unum * (vnum - 1) * 2;
	
	
	WMSphereVertex *vertexData = new WMSphereVertex[numberOfVertices];
	if (!vertexData) {
		NSLog(@"Out of mem");
		return NO;
	}
	
	unsigned short *indexData = new unsigned short [numberOfTriangles * 3]; 
	if (!indexData) {
		NSLog(@"Out of mem");
		return NO;
	}
	
	GLKVector3 spherePosition = GLKVector3Make(0.0f, 0.045f, 0.0f);
	
	//Add vertices
	for (int u=0, i=0, indexDataIndex=0; u<unum; u++) {
		for (int v=0; v<vnum; v++, i++) {
			float theta = u * 2.0f * M_PI / unum;
			float phi = v * M_PI / vnum;
			//Add the vertex
			vertexData[i].n = (GLKVector3){sinf(phi)*cosf(theta), sinf(phi)*sinf(theta), cosf(phi)};
			vertexData[i].p = radius * vertexData[i].n + spherePosition;
			vertexData[i].tc = (GLKVector2){theta, phi};
			
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
	for (int i=0; i<numberOfTriangles*3; i++) {
		maxRefI = MAX(maxRefI, indexData[i]);
	}
	ZAssert(maxRefI < unum * vnum, @"Bad tri index!");
#endif
	
	WMStructureDefinition *vertexDef = [[WMStructureDefinition alloc] initWithFields:WMQuadVertex_fields count:3 totalSize:sizeof(WMSphereVertex)];
	
	WMStructuredBuffer *vertexBuffer = [[WMStructuredBuffer alloc] initWithDefinition:vertexDef];
	[vertexBuffer appendData:vertexData withStructure:vertexDef count:numberOfVertices];
	
	
	WMStructureDefinition *indexDef = [[WMStructureDefinition alloc] initWithAnonymousFieldOfType:WMStructureTypeUnsignedShort];
	WMStructuredBuffer *indexBuffer = [[WMStructuredBuffer alloc] initWithDefinition:indexDef];
	[indexBuffer appendData:indexData withStructure:indexDef count:numberOfTriangles * 3];

	
	WMRenderObject *ro = [[WMRenderObject alloc] init];
	
	ro.shader = shader;
	ro.vertexBuffer = vertexBuffer;
	ro.indexBuffer = indexBuffer;
	
	ro.renderType = GL_TRIANGLE_STRIP;
	ro.renderDepthState = DNGLStateDepthTestEnabled;
	ro.renderBlendState = 0;
	
	_outputSphere.object = ro;
	
	return YES;
}

- (BOOL)execute:(WMEAGLContext *)context time:(double)time arguments:(NSDictionary *)args;
{
	//TODO: replace radius with a transformation matrix!
	BOOL dirty = radius != _inputRadius.value || unum != _inputUCount.index || vnum != _inputVCount.index || radius != _inputRadius.value;
	
	if (dirty) {
		return [self recreateVertexData];
	} else {
		return YES;
	}
}



@end
