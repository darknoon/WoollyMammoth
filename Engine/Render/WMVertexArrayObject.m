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

#if TARGET_OS_IPHONE && GL_OES_vertex_array_object
void (* const wm_glBindVertexArray)(GLuint) = &glBindVertexArrayOES;
void (* const wm_glDeleteVertexArrays)(GLsizei n, const GLuint *arrays) = &glDeleteVertexArraysOES;
void (* const wm_glGenVertexArrays)(GLsizei n, GLuint *arrays) = &glGenVertexArraysOES;
#elif (WM_OGL_VERSION == 3)
void (* const wm_glBindVertexArray)(GLuint) = &glBindVertexArray;
void (* const wm_glDeleteVertexArrays)(GLsizei n, const GLuint *arrays) = &glDeleteVertexArrays;
void (* const wm_glGenVertexArrays)(GLsizei n, GLuint *arrays) = &glGenVertexArrays;
#elif TARGET_OS_MAC && (WM_OGL_VERSION == 2)
void (* const wm_glBindVertexArray)(GLuint) = &glBindVertexArrayAPPLE;
void (* const wm_glDeleteVertexArrays)(GLsizei n, const GLuint *arrays) = &glDeleteVertexArraysAPPLE;
void (* const wm_glGenVertexArrays)(GLsizei n, GLuint *arrays) = &glGenVertexArraysAPPLE;
#endif

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

	wm_glGenVertexArrays(1, &vao);
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
		wm_glDeleteVertexArrays(1, &vao);
	}
}

- (BOOL)isEqual:(id)object;
{
	if (object == self) return YES;
	if ([object isKindOfClass:[self class]]) {
		return [self isEqualToVertexArrayObject:object];
	} else {
		return NO;
	}
}

- (BOOL)isEqualToVertexArrayObject:(WMVertexArrayObject *)object;
{
	if (object == self) return YES;
	return [buffers isEqualToArray:object->buffers] && [attributeNames isEqualToOrderedSet:object->attributeNames] && [attributeLocations isEqualToOrderedSet:object->attributeLocations];
}

- (NSString *)description;
{
	return [NSString stringWithFormat:@"<%@ :%p obj:%d attrib count:%d>", [self class], self, vao, attributeNames.count];
}

@end
