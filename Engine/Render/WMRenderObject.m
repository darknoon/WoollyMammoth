//
//  WMRenderObject.m
//  WMEdit
//
//  Created by Andrew Pouliot on 7/24/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMRenderObject.h"

#import "WMStructuredBuffer.h"
#import "WMRenderObject_WMEAGLContext_Private.h"
#import "WMGLStateObject_WMEAGLContext_Private.h"
#import "WMVertexArrayObject.h"

@interface WMRenderObject()
//Private state for WMEAGLContext
@property (nonatomic, strong) WMVertexArrayObject *vertexArrayObject;
@property (nonatomic) BOOL vertexArrayObjectDirty;
@end

NSString *const WMRenderObjectTransformUniformName = @"wm_T";

@implementation WMRenderObject {
	NSMutableDictionary *uniformValues;
}

@synthesize vertexBuffer;
@synthesize indexBuffer;
@synthesize shader;

@synthesize renderType;
@synthesize renderRange;
@synthesize renderBlendState;
@synthesize renderDepthState;

@synthesize vertexArrayObject;
@synthesize vertexArrayObjectDirty;

- (id)init;
{
    self = [super init];
	if (!self) return nil;
	
	renderType = GL_TRIANGLES;
	renderRange = (NSRange){.length = NSIntegerMax};
    
	renderBlendState = 0;
	renderDepthState = 0;
	
	uniformValues = [[NSMutableDictionary alloc] init];
	
    return self;
}

- (id)copyWithZone:(NSZone *)zone;
{
	WMRenderObject *copy = [[WMRenderObject allocWithZone:zone] init];
	
	copy->vertexBuffer = vertexBuffer;
	copy->indexBuffer = indexBuffer;
	copy->shader = shader;

	copy->renderType = renderType;
	copy->renderRange = renderRange;
	copy->renderBlendState = renderBlendState;
	copy->renderDepthState = renderDepthState;
	
	copy->vertexArrayObject = vertexArrayObject;
	copy->vertexArrayObjectDirty = vertexArrayObjectDirty;

	copy->uniformValues = [uniformValues mutableCopy];
	
	return copy;
}

- (void)setVertexBuffer:(WMStructuredBuffer *)inVertexBuffer;
{
	if (vertexBuffer != inVertexBuffer) {
		vertexArrayObjectDirty = YES;
		vertexBuffer = inVertexBuffer;
	}
}

- (void)setIndexBuffer:(WMStructuredBuffer *)inIndexBuffer;
{
	if (indexBuffer != inIndexBuffer) {
		vertexArrayObjectDirty = YES;
		indexBuffer = inIndexBuffer;
	}
}

- (void)setShader:(WMShader *)inShader;
{
	if (shader != inShader) {
		vertexArrayObjectDirty = YES;
		shader = inShader;
	}
}

+ (NSString *)stringFromGLRenderType:(GLenum)inType;
{
	if (inType >= GL_POINTS && inType <= GL_TRIANGLE_FAN) {
		NSString *names[] = {@"points", @"lines", @"line loop", @"line strip", @"triangles", @"triangle strip", @"triangle fan"};
		return names[inType - GL_POINTS];
	} else {
		return @"<invalid render type>";
	}
}

- (NSString *)description;
{
	return [NSString stringWithFormat:@"<%@ %p vb:%@ ib:%@ shader:%@ renderType:%@ range:%@ renderBlendState:%d renderDepthState:%d vao:%@>",
			[self class], self, vertexBuffer, indexBuffer, shader, [WMRenderObject stringFromGLRenderType:renderType], NSStringFromRange(renderRange), renderBlendState, renderDepthState, vertexArrayObject];
}

- (NSArray *)uniformKeys;
{
	return [uniformValues allKeys];
}

- (void)setValue:(id)inValue forUniformWithName:(NSString *)inUniformName;
{
	[uniformValues setObject:inValue forKey:inUniformName];
}

- (id)valueForUniformWithName:(NSString *)inUniformName;
{
	return [uniformValues objectForKey:inUniformName];
}

- (void)premultiplyTransform:(GLKMatrix4)inMatrix;
{
	GLKMatrix4 matrix = GLKMatrix4Identity;
	NSValue *transformValue = (NSValue *)[self valueForUniformWithName:WMRenderObjectTransformUniformName];
	BOOL isMatrix = transformValue && strcmp([transformValue objCType], @encode(GLKMatrix4)) == 0;
	if (isMatrix) {
		[transformValue getValue:&matrix];
		matrix = GLKMatrix4Multiply(inMatrix, matrix);
	} else {
		matrix = inMatrix;
	}
	transformValue = [NSValue valueWithBytes:&matrix objCType:@encode(GLKMatrix4)];
	[self setValue:transformValue forUniformWithName:WMRenderObjectTransformUniformName];
}

- (void)postmultiplyTransform:(GLKMatrix4)inMatrix;
{
	GLKMatrix4 matrix = GLKMatrix4Identity;
	NSValue *transformValue = (NSValue *)[self valueForUniformWithName:WMRenderObjectTransformUniformName];
	BOOL isMatrix = transformValue && strcmp([transformValue objCType], @encode(GLKMatrix4)) == 0;
	if (isMatrix) {
		[transformValue getValue:&matrix];
		matrix = GLKMatrix4Multiply(matrix, inMatrix);
	} else {
		matrix = inMatrix;
	}
	transformValue = [NSValue valueWithBytes:&matrix objCType:@encode(GLKMatrix4)];
	[self setValue:transformValue forUniformWithName:WMRenderObjectTransformUniformName];
}

@end
