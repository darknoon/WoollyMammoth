//
//  WMStructureDefinition.m
//  WMViewer
//
//  Created by Andrew Pouliot on 7/10/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMStructureDefinition.h"

size_t WMStructureFieldSize(WMStructureField inField) {
	return WMStructureTypeSize(inField.type) * inField.count;
}

size_t WMStructureTypeSize(WMStructureType inType) {
	switch (inType) {
		case WMStructureTypeByte:
		case WMStructureTypeUnsignedByte:
			return sizeof(char);
		case WMStructureTypeShort:
		case WMStructureTypeUnsignedShort:
			return sizeof(short);
		case WMStructureTypeInt:
		case WMStructureTypeUnsignedInt:
		case WMStructureTypeFixed:
			return sizeof(int);
		case WMStructureTypeFloat:
			return sizeof(float);
		default:
			return 0;
	}
};

@implementation WMStructureDefinition {
	int fieldCount;
	WMStructureField *fields;
}

@synthesize size;
	
//- (id)initWithFields:(const WMStructureField *)firstField, ... NS_REQUIRES_NIL_TERMINATION;

- (id)initWithAnonymousFieldOfType:(WMStructureType)inType;
{
	const WMStructureField field = {.name = "", .type = inType, .count = 1};
	return [self initWithFields:&field count:1];
}

- (id)initWithFields:(const WMStructureField *)inFields count:(NSUInteger)inCount;
{
	if (!inFields || inCount < 1) {
		[self release];
		return nil;
	}
	
	self = [super init];
	if (!self) return nil;
	
	fields = malloc(inCount * sizeof(WMStructureField));
	if (!fields) {
		[self release];
		return nil;
	}
	memcpy(fields, inFields, inCount * sizeof(WMStructureField));
	fieldCount = inCount;
	
	for (int i=0; i<fieldCount; i++) {
		size += WMStructureFieldSize(fields[i]);
	}
	if (fieldCount > 100 || size > 1000 ) {
		NSLog(@"Huge structure size: %d fieldCount: %d", size, fieldCount);
	}
	
	return self;
}

- (void)dealloc {
	if (fields) free(fields);
    [super dealloc];
}


- (BOOL)isSingleType;
{
	return fieldCount == 1 && fields[0].count == 1;
}

- (NSInteger)offsetOfField:(NSString *)inField;
{
	char inName[256];
	BOOL ok = [inField getCString:inName maxLength:255 encoding:NSASCIIStringEncoding];
	if (ok) {
		NSInteger byteOffset = 0;
		for (int i=0; i<fieldCount; i++) {
			if (strncmp(inName, fields[i].name, 255) != 0) {
				byteOffset += WMStructureFieldSize(fields[i]);
			} else {
				//Found the field. Done.
				break;
			}
		}
		return byteOffset;
	} else {
		return -1;
	}
}

- (NSInteger)sizeOfField:(NSString *)inField;
{
	char inName[256];
	BOOL ok = [inField getCString:inName maxLength:255 encoding:NSASCIIStringEncoding];
	if (ok) {
		for (int i=0; i<fieldCount; i++) {
			if (strncmp(inName, fields[i].name, 255) == 0) {
				return WMStructureFieldSize(fields[i]);
			}
		}
	}
	return -1;
}

- (NSUInteger)size;
{
	return size;
}


- (NSString *)descriptionOfData:(const void *)inData;
{
	NSMutableString *str = [NSMutableString stringWithString:@"{"];
	
	NSUInteger offset = 0;
	for (int i=0; i<fieldCount; i++) {
		[str appendFormat:@"%s = {", fields[i].name];
		
		for (int j=0; j<fields[i].count; j++) {
			const void *ptr = inData + offset;
			
			switch (fields[i].type) {
				case WMStructureTypeByte:
					[str appendFormat:@"%d", (int)*(char *)(ptr)];
					break;
				case WMStructureTypeUnsignedByte:
					[str appendFormat:@"%d", (int)*(unsigned char *)(ptr)];
					break;
				case WMStructureTypeShort:
					[str appendFormat:@"%d", (int)*(short *)(ptr)];
					break;
				case WMStructureTypeUnsignedShort:
					[str appendFormat:@"%d", (int)*(unsigned short *)(ptr)];
					break;
				case WMStructureTypeInt:
					[str appendFormat:@"%i", *(int *)(ptr)];
					break;
				case WMStructureTypeUnsignedInt:
					[str appendFormat:@"%u", *(unsigned int *)(ptr)];
					break;
				case WMStructureTypeFloat:
					[str appendFormat:@"%.5f", *(float *)(ptr)];
					break;
				case WMStructureTypeFixed:
					[str appendFormat:@"fixed point %d ~= %.5lf", *(int *)(ptr), ((double)(*(int *)(ptr))) / 65536];
					break;
				default:
					[str appendString:@"??"];
					break;
			}
			[str appendString:@", "];
		}
		offset += WMStructureFieldSize(fields[i]);
		[str appendString:@"}, "];
	}

	[str appendString:@"}"];
	return str;
}

- (NSString *)description;
{
	return [NSString stringWithFormat:@"<%@ : %p size:%d fields:%d>", [self class], self, size, fieldCount];
}

- (void)enumerateFieldsWithBlock:(void( (^)(NSUInteger idx, const WMStructureField *field, NSUInteger offset)))inBlock;
{
	if (!inBlock) return;
	
	NSUInteger byteOffset = 0;
	for (int i=0; i<fieldCount; i++) {
		inBlock(i, &fields[i], byteOffset);
		byteOffset += WMStructureFieldSize(fields[i]);
	}
}

- (BOOL)getFieldNamed:(NSString *)inField outField:(WMStructureField *)outField outOffset:(NSUInteger *)outOffset;
{
	char inName[256];
	BOOL ok = [inField getCString:inName maxLength:255 encoding:NSASCIIStringEncoding];
	if (ok) {
		NSInteger byteOffset = 0;
		for (int i=0; i<fieldCount; i++) {
			if (strncmp(inName, fields[i].name, 255) != 0) {
				byteOffset += WMStructureFieldSize(fields[i]);
			} else {
				if (outField)  *outField = fields[i];
				if (outOffset) *outOffset = byteOffset;
				return YES;
			}
		}
	}
	return NO;
}

@end
