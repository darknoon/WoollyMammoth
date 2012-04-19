//
//  WMVertexArrayObject.m
//  WMEdit
//
//  Created by Andrew Pouliot on 10/30/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import "WMVertexArrayObject.h"
#import "WMStructuredBuffer.h"
#import "WMStructuredBuffer_WMEAGLContext_Private.h"

@implementation WMVertexArrayObject {
	GLuint vao;
	NSArray *buffers;
	WMStructuredBuffer *indexBuffer;
	NSOrderedSet *attributeNames;
	NSOrderedSet *attributeLocations;
}
@synthesize glObject = vao;

- (id)initWithVertexBuffers:(NSArray *)inBuffers attributeNames:(NSOrderedSet *)inAttributeNames attributeLocations:(NSOrderedSet *)inAttributeLocations indexBuffer:(WMStructuredBuffer *)inIndexBuffer;
{
	if (inAttributeNames.count == 0) {
		DLog(@"Must specify some attribute names!");
		return nil;
	}
	if ( !( (inBuffers.count == inAttributeNames.count) && (inBuffers.count == inAttributeLocations.count) ) ) {
		DLog(@"Buffer count must equal attribute name count and attribute location count (%d %d %d)", inBuffers.count, inAttributeNames.count, inAttributeLocations.count);
		return nil;
	}
	
	self = [super init];
	if (!self) return nil;
	
	//Not deep copies, just make sure nobody is mutating behind our backs
	buffers = [inBuffers copy];
	attributeNames = [inAttributeNames copy];
	attributeLocations = [inAttributeLocations copy];
	indexBuffer = inIndexBuffer;

#if GL_OES_vertex_array_object
	glGenVertexArraysOES(1, &vao);
#else
	glGenVertexArrays(1, &vao);
#endif
	ZAssert(vao, @"couldn't create vao");

	return self;
}

- (void)refreshGLObject;
{
#if DEBUG_OPENGL && GL_OES_vertex_array_object
	{
		GLint oi;
		glGetIntegerv(GL_VERTEX_ARRAY_BINDING_OES, &oi);
		ZAssert(vao == oi, @"Incorrect vao bound!");
	}
#endif
	
	for (NSUInteger i=0; i<attributeNames.count; i++) {
		WMStructuredBuffer *buffer = [buffers objectAtIndex:i];
		WMStructureDefinition *vertexDefinition = buffer.definition;
		NSString *attribute = [attributeNames objectAtIndex:i];
		
		NSInteger location = [[attributeLocations objectAtIndex:i] integerValue];
		
		WMStructureField f;
		if (location != -1 && [vertexDefinition getFieldNamed:attribute outField:&f]) {
			glEnableVertexAttribArray(location);
			
			glBindBuffer(GL_ARRAY_BUFFER, buffer.bufferObject);
			
			//Set up vertex state. 
			//TODO: check if the attributes are compatible!
			//TODO: separate this logic out into a -[WMShader compatibleAttibributesWithDefinition] ?
			glVertexAttribPointer(location, f.count, f.type, f.normalized, vertexDefinition.size, (void *)f.offset);
		}
	}
	
	if (indexBuffer) {
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer.bufferObject);
	}
}

- (void)deleteInternalState;
{
	if (vao) {
#if GL_OES_vertex_array_object
		glDeleteVertexArraysOES(1, &vao);
#else
		glDeleteVertexArrays(1, &vao);
#endif
	}
}

- (BOOL)isEqual:(id)object;
{
	if ([object isKindOfClass:[self class]]) {
		return [self isEqualToVertexArrayObject:object];
	} else {
		return NO;
	}
}

- (BOOL)isEqualToVertexArrayObject:(WMVertexArrayObject *)inObject;
{
	return [buffers isEqualToArray:inObject->buffers] && [attributeNames isEqualToOrderedSet:inObject->attributeNames] && [attributeLocations isEqualToOrderedSet:inObject->attributeLocations];
}

- (NSString *)description;
{
	return [NSString stringWithFormat:@"<%@ :%p obj:%d attrib count:%d>", [self class], self, vao, attributeNames.count];
}

@end
