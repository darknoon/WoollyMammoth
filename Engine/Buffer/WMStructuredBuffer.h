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

/**
 @abstract Represents a contiguous buffer with associated type information about its contents.
 @discussion WMStructuredBuffer enables interleaved data buffers for vertex data, used in WMRenderObject for rendering.
 
 Generally, contents be interleaved as so (pseudocode):
 
 	array{{float position[4], char color[4]}, {float position[4], char color[4]}, {... count - 1 }
 
 A structured may also be resident on the GPU as a Vertex Buffer Object (VBO). Generally, OpenGL buffer allocation occurs when you render a WMRenderObject with the structured buffer as a vertex or index buffer. If the OpenGL buffer has been allocated, you can use -mapForWritingWithBlock: to obtain a pointer to the shared memory for efficient submission of the data to the GPU. */

@interface WMStructuredBuffer : WMGLStateObject

/** @abstract Create a new structured buffer. */
- (id)initWithDefinition:(WMStructureDefinition *)inDefinition;

@property (nonatomic, strong, readonly) WMStructureDefinition *definition;


/** @name Structured data API */

/**
 @abstract The number of used elements in the buffer.
 @discussion Setting the count will resize the buffer. */
@property (nonatomic) NSUInteger count;

/**
 @abstract Append raw data to the buffer
 @discussion Reads elementSize * count bytes from data, copies into the internal buffer
 @param data
*/
- (void)appendData:(const void *)data withStructure:(WMStructureDefinition *)structure count:(NSUInteger)count;

/**
 @abstract Replace data in the buffer at a given index
 @discussion Reads one element from data, writes it at a specific index in the buffer
 @param data A pointer to the provided data
 @param structure *unused*
 @param idx The index in the buffer at which to replace the data
 */
- (void)replaceData:(const void *)data withStructure:(WMStructureDefinition *)structure atIndex:(NSUInteger)idx;


/** @abstract Replace data in the buffer in a range
 @discussion Reads a range of the data, writes it into the buffer
 @param data A pointer to the provided data
 @param structure *unused*
 @param range The range of data
 */
- (void)replaceData:(const void *)data withStructure:(WMStructureDefinition *)structure inRange:(NSRange)range;

//TODO:
//-(void)beginUpdates
//-(void)endUpdates


/**
 @abstract Append raw data to the buffer
 @param blockWithMappedMemory A block to be called with a pointer to the mapped memory. The pointer is only valid inside the block submitted for rendering.
 @discussion Check void *ptr is not NULL! NULL indicates the buffer could not be mapped for whatever reason. The buffer must have been used in rendering get a buffer.
 
 Calls glMapBuffer() internally.
 */
- (void)mapForWritingWithBlock:(void (^)(void *ptr))blockWithMappedMemory;

//This is a more raw API. Not sure it's a good idea.
- (NSUInteger)dataSize;
- (void *)dataPointer;
- (const void *)pointerToField:(NSString *)inField atIndex:(NSUInteger)inIndex;
- (void)markRangeDirty:(NSRange)inRange;

@end
