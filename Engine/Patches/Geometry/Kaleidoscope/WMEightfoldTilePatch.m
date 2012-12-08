//
//  WMEightfoldTilePatch.m
//  VideoLiveEffect
//
//  Created by Andrew Pouliot on 5/23/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMEightfoldTilePatch.h"

#import "DNKaleidoscopeGeometryVariable.h"
#import "WMEAGLContext.h"
#import "WMShader.h"
#import "WMStructuredBuffer.h"
#import "WMRenderObject.h"

static WMStructureField WMKaleidoscopeVertex_fields[] = {
	{.name = "position",  .type = WMStructureTypeFloat,     .count = 2, .normalized = NO,  .offset = offsetof(KaleidoscopeGeometryPoint, v)},
	{.name = "texCoord0",  .type = WMStructureTypeFloat,    .count = 2, .normalized = NO,  .offset = offsetof(KaleidoscopeGeometryPoint, tc)},
};



@implementation WMEightfoldTilePatch {
	DNKaleidoscopeGeometryVariable *geometry;
	WMStructuredBuffer *vertices;
	WMStructuredBuffer *indices;
	WMShader *shader;
}

+ (void)load;
{
	@autoreleasepool {
		[self registerPatchClass];
	}
}

+ (id)defaultValueForInputPortKey:(NSString *)inKey;
{
	if ([inKey isEqualToString:@"inputScale"]) {
		return [NSNumber numberWithFloat:1.0f];
	}
	return nil;
}

+ (NSString *)humanReadableTitle;
{
	return @"Pseudo-Kaleidoscope";
}

+ (NSString *)category;
{
	return WMPatchCategoryGeometry;
}

- (BOOL)setup:(WMEAGLContext *)inContext;
{
	geometry = [[DNKaleidoscopeGeometryVariable alloc] init];

	shader = [WMShader defaultShader];

	inputAngle.minValue = -180.f;
	inputAngle.maxValue = 180.f;

	WMStructureDefinition *def = [[WMStructureDefinition alloc] initWithFields:WMKaleidoscopeVertex_fields count:sizeof(WMKaleidoscopeVertex_fields) / sizeof(WMStructureField) totalSize:sizeof(KaleidoscopeGeometryPoint)];
	vertices = [[WMStructuredBuffer alloc] initWithDefinition:def];
	
	WMStructureDefinition *idef = [[WMStructureDefinition alloc] initWithAnonymousFieldOfType:WMStructureTypeUnsignedShort];
	indices = [[WMStructuredBuffer alloc] initWithDefinition:idef];
	
	return YES;
}

- (void)cleanup:(WMEAGLContext *)inContext;
{
}

- (BOOL)execute:(WMEAGLContext *)inContext time:(double)time arguments:(NSDictionary *)args;
{
	CGFloat screenAspect = 1.5f;
	
	geometry.scale = 2.0f;
	geometry.textureCoordinateScale = inputScale.value;
	//	geometry.mirrorAngle = mirrorAngle;
	geometry.mirrorAngle = M_PI_4;
	geometry.offset = (CGPoint) {inputOffsetX.value, inputOffsetY.value};
	geometry.aspectRatioCorrection = screenAspect;
	geometry.textureCoordinateAngle = inputAngle.value * M_PI / 180.0;
	[geometry generateBuffers];
	
	//Upload to structured buffers
	vertices.count = 0;
	[vertices appendData:[geometry points] withStructure:vertices.definition count:[geometry pointsCount]];
	
	indices.count = 0;
	[indices appendData:[geometry triangleIndices] withStructure:indices.definition count:[geometry triangleIndicesCount]];
	
	WMRenderObject *ro = [[WMRenderObject alloc] init];
	
	[ro setValue:inputColor.objectValue forUniformWithName:@"color"];
	[ro setValue:inputImage.image forUniformWithName:@"texture"];
	
	ro.renderBlendState = 0;
	ro.renderDepthState = 0;
	ro.shader = shader;
	ro.vertexBuffer = vertices;
	ro.indexBuffer = indices;
	
	outputObject.object = ro;
	
	return YES;
}

@end
