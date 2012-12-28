//
//  WMVertexArrayObject.h
//  WMEdit
//
//  Created by Andrew Pouliot on 10/30/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import "WMGLStateObject.h"

@class WMStructuredBuffer;

//Pointers to the relevant functions for your enjoyment
void (* const wm_glBindVertexArray)(GLuint);
void (* const wm_glDeleteVertexArrays)(GLsizei n, const GLuint *arrays);
void (* const wm_glGenVertexArrays)(GLsizei n, GLuint *arrays);

//THIS WHOLE CLASS IS PRIVATE

//WMVertexArrayObject is immutable
@interface WMVertexArrayObject : WMGLStateObject

- (id)initWithVertexBuffers:(NSArray *)inBuffers attributeNames:(NSOrderedSet *)inAttributeNames attributeLocations:(NSOrderedSet *)inAttributeLocations indexBuffer:(WMStructuredBuffer *)inBuffer;

- (void)refreshGLObject;

@property (nonatomic) GLuint glObject;

- (BOOL)isEqualToVertexArrayObject:(WMVertexArrayObject *)inObject;

@end
