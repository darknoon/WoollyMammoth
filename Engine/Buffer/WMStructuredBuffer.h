//
//  WMStructuredBuffer.h
//  WMViewer
//
//  Created by Andrew Pouliot on 7/10/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMStructureDefinition.h"
#import "WMRenderCommon.h"
#import "WMGLStateObject.h"

//WMStructuredBuffer Represents a contiguous buffer with associated type information about its contents.
//Generally, something like array{{float position[4], char color[4]}, {float position[4], char color[4]}, ... count - 1 }
//May be resident on the GPU as a Vertex Array Object (VAO), but this state is private to the render system.
//Generally, upload occurs when you use one of these to render.

@interface WMStructuredBuffer : WMGLStateObject

- (id)initWithDefinition:(WMStructureDefinition *)inDefinition;

@property (nonatomic, strong, readonly) WMStructureDefinition *definition;

//Can set or get count, ie resize buffer.
@property (nonatomic) NSUInteger count;

//Reads elementSize * count bytes from inData, copies into buffer
- (void)appendData:(const void *)inData withStructure:(WMStructureDefinition *)inStructure count:(NSUInteger)inCount;

//Reads one element from inData, writes it at a specific index in the buffer
- (void)replaceData:(const void *)inData withStructure:(WMStructureDefinition *)inStructure atIndex:(NSUInteger)inIndex;
//Reads some data, writes into buffer
- (void)replaceData:(const void *)inData withStructure:(WMStructureDefinition *)inStructure inRange:(NSRange)inRange;

//TODO:
//-(void)beginUpdates
//-(void)endUpdates

//Check void *ptr is not NULL! NULL indicates the buffer could not be mapped for whatever reason.
//If the buffer has been submitted to OpenGL, then you'll get a buffer from glMapBuffer()
- (void)mapForWritingWithBlock:(void (^)(void *ptr))blockWithMappedMemory;

- (NSUInteger)dataSize;
- (void *)dataPointer;
- (const void *)pointerToField:(NSString *)inField atIndex:(NSUInteger)inIndex;
- (void)markRangeDirty:(NSRange)inRange;

@end
