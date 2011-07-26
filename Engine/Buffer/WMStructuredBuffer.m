//
//  WMStructuredBuffer.m
//  WMViewer
//
//  Created by Andrew Pouliot on 7/10/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMStructuredBuffer.h"

#import "WMEAGLContext.h"

@implementation WMStructuredBuffer

@synthesize definition;
@synthesize count;

- (id)initWithDefinition:(WMStructureDefinition *)inDefinition;
{
    self = [super init];
    if (!self) return nil;
	
	data = [[NSMutableData alloc] init];
	if (!data) {
		[self release];
		return nil;
	}
	
	definition = [inDefinition retain];
    
    return self;
}

- (void)dealloc {
	[self releaseBufferObject];
    [definition release];
    [super dealloc];
}

- (void)setCount:(NSUInteger)inCount;
{
	[data setLength:definition.size * inCount];
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
	count += inCount;
	[data appendBytes:inData length:inStructure.size * inCount];
}

- (void)replaceData:(const void *)inData withStructure:(WMStructureDefinition *)inStructure atIndex:(NSUInteger)inIndex;
{
	//Resize if necessary
	if (inIndex + 1 > count) {
		self.count = MAX(inIndex + 1, count);
	}
	NSRange replacementRange = NSMakeRange(inIndex * definition.size, 1 * definition.size);
	[data replaceBytesInRange:replacementRange withBytes:inData];
}

- (void)replaceData:(const void *)inData withStructure:(WMStructureDefinition *)inStructure inRange:(NSRange)inRange;
{
	//Resize if necessary
	if (NSMaxRange(inRange) > count) {
		self.count = MAX(NSMaxRange(inRange), count);
	}
	NSRange replacementRange = NSMakeRange(inRange.location * definition.size, inRange.length * definition.size);
	[data replaceBytesInRange:replacementRange withBytes:inData];
}

- (NSUInteger)dataSize;
{
	return count * definition.size;
}

- (const void *)dataPointer;
{
	if (data.length > 0) return [data bytes];
	return NULL;
}

- (const void *)pointerToField:(NSString *)inField atIndex:(NSUInteger)inIndex;
{
	if (self.count < inIndex) {
		NSInteger offset = [definition offsetOfField:inField];
		if (offset != -1) {
			return [data bytes] + offset;
		}
	}
	return NULL;
}

- (const void *)pointerToStructureAtIndex:(NSUInteger)inIndex;
{
	return self.dataPointer + inIndex * definition.size;
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
