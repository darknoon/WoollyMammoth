//
//  WMStructuredBuffer.m
//  WMViewer
//
//  Created by Andrew Pouliot on 7/10/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMStructuredBuffer.h"

#import "WMEAGLContext.h"
#import "WMStructuredBuffer_WMEAGLContext_Private.h"

@implementation WMStructuredBuffer {
	void *data;
	size_t dataSize;	
}

static inline unsigned int nextPowerOf2(unsigned int v) {
	v--;
	v |= v >> 1;
	v |= v >> 2;
	v |= v >> 4;
	v |= v >> 8;
	v |= v >> 16;
	return v+1;
};

@synthesize definition;
@synthesize count;

- (id)initWithDefinition:(WMStructureDefinition *)inDefinition;
{
    self = [super init];
    if (!self) return nil;
		
	definition = inDefinition;
    
	dirtySet = [[NSMutableIndexSet alloc] init];
	
    return self;
}

- (void)dealloc {
	if (data) {
		free(data);
	}
}

- (void)setCount:(NSUInteger)inCount;
{
	if (dataSize < definition.size * inCount) {
		dataSize = nextPowerOf2(definition.size * inCount);
		data = realloc(data, dataSize);
	} else if (dataSize > nextPowerOf2(definition.size * inCount) ) {
		dataSize = nextPowerOf2(definition.size * inCount);
		if (inCount == 0) {
			if (data)
				free(data);
			data = NULL;
		} else {
			data = realloc(data, nextPowerOf2(definition.size * inCount));
			if (!data) {
				dataSize = 0;
			}
		}
	}
	//ZAssert(data.length == inCount * definition.size, @"Didn't set data size");
	count = inCount;
}

- (NSUInteger)count;
{
	//ZAssert(count == data.length / definition.size, @"Unexpected data size");
	return count;
}

- (void)appendData:(const void *)inData withStructure:(WMStructureDefinition *)inStructure count:(NSUInteger)inCount;
{
	NSUInteger prevCount = count;
	self.count += inCount;
	memcpy(data + prevCount * definition.size, inData, inCount * definition.size);
	[dirtySet addIndexesInRange:(NSRange){count - inCount, inCount}];
}

- (void)replaceData:(const void *)inData withStructure:(WMStructureDefinition *)inStructure atIndex:(NSUInteger)inIndex;
{
	//Resize if necessary
	if (inIndex + 1 > count) {
		self.count = MAX(inIndex + 1, count);
	}
	NSRange replacementRange = NSMakeRange(inIndex * definition.size, 1 * definition.size);
	memcpy(data + replacementRange.location, inData, replacementRange.length);
	[dirtySet addIndex:inIndex];
}

- (void)replaceData:(const void *)inData withStructure:(WMStructureDefinition *)inStructure inRange:(NSRange)inRange;
{
	//Resize if necessary
	if (NSMaxRange(inRange) > count) {
		self.count = MAX(NSMaxRange(inRange), count);
	}
	NSRange replacementRange = NSMakeRange(inRange.location * definition.size, inRange.length * definition.size);
	memcpy(data + replacementRange.location, inData, replacementRange.length);
	[dirtySet addIndexesInRange:inRange];
}

- (NSUInteger)dataSize;
{
	return count * definition.size;
}

- (void *)dataPointer;
{
	if (dataSize > 0) return data;
	return NULL;
}

- (const void *)pointerToField:(NSString *)inField atIndex:(NSUInteger)inIndex;
{
	if (self.count < inIndex) {
		NSInteger offset = [definition offsetOfField:inField];
		if (offset != -1) {
			return data + offset;
		}
	}
	return NULL;
}

- (const void *)pointerToStructureAtIndex:(NSUInteger)inIndex;
{
	return self.dataPointer + inIndex * definition.size;
}

- (void)markRangeDirty:(NSRange)inRange;
{
	[dirtySet addIndexesInRange:inRange];
}

- (NSString *)description;
{
	NSString *bufferObjectString = bufferObject ? [NSString stringWithFormat:@" bufferObject: %d", bufferObject] : @"";
	return [NSString stringWithFormat:@"<%@ : %p = %d @ %d bytes = %d%@>", [self class], self, count, definition.size, self.dataSize, bufferObjectString];
}

- (NSString *)debugDescription;
{
	NSMutableString *dataDesc = [NSMutableString stringWithFormat:@"<%@ : %p = %d @ %d bytes = %d [", [self class], self, count, definition.size, self.dataSize];
	
	const NSUInteger maxDescription = 102;
	
	for (int i=0; i<count; i++) {
		[dataDesc appendString:[definition descriptionOfData:[self pointerToStructureAtIndex:i]]];
		[dataDesc appendString:@",\n"];
		if (i > maxDescription) {
			[dataDesc appendFormat:@"... and %d more", count - maxDescription];
			break;
		}
	}
	
	[dataDesc appendString:@"]>"];
	return dataDesc;
}

@end
