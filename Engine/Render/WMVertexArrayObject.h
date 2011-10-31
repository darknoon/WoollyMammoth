//
//  WMVertexArrayObject.h
//  WMEdit
//
//  Created by Andrew Pouliot on 10/30/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import "WMGLStateObject.h"

@class WMStructuredBuffer;

//THIS WHOLE CLASS IS PRIVATE
//TODO: make private header

//Immutable type
@interface WMVertexArrayObject : WMGLStateObject

- (id)initWithVertexBuffers:(NSArray *)inBuffers attributeNames:(NSOrderedSet *)inAttributeNames attributeLocations:(NSOrderedSet *)inAttributeLocations indexBuffer:(WMStructuredBuffer *)inBuffer;

- (void)refreshGLObject;

@property (nonatomic) GLuint glObject;

- (BOOL)isEqualToVertexArrayObject:(WMVertexArrayObject *)inObject;

@end
