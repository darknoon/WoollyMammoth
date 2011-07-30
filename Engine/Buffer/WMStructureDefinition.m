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
@synthesize shouldAlignTo4ByteBoundary;

//- (id)initWithFields:(const WMStructureField *)firstField, ... NS_REQUIRES_NIL_TERMINATION;

- (id)initWithAnonymousFieldOfType:(WMStructureType)inType;
{
	const WMStructureField field = {.name = "", .type = inType, .count = 1};
	return [self initWithFields:&field count:1 totalSize:WMStructureTypeSize(inType)];
}

- (id)initWithFields:(const WMStructureField *)inFields count:(NSUInteger)inCount totalSize:(size_t)totalSize;
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
	
	NSUInteger sizeMinBound = 0.0;
	
	for (int i=0; i<fieldCount; i++) {
		sizeMinBound += WMStructureFieldSize(fields[i]);
	}
	ZAssert(totalSize >= sizeMinBound, @"Size given is too small to possibly contain all the fields!");
	size = MAX(sizeMinBound, totalSize);
	
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
		for (int i=0; i<fieldCount; i++) {
			if (strncmp(inName, fields[i].name, 255) != 0) {
				return fields[i].offset;
			}
		}
	}
	return -1;
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
	//Round up to nearest boundary if necessary
	return shouldAlignTo4ByteBoundary ? ((size + 4-1) / 4) * 4 : size;
}


- (NSString *)descriptionOfData:(const void *)inData;
{
	NSMutableString *str = [NSMutableString stringWithString:@"{"];
	
	for (int i=0; i<fieldCount; i++) {
		[str appendFormat:@"%s = {", fields[i].name];

		NSUInteger offset = fields[i].offset;
		
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
			offset += WMStructureTypeSize(fields[i].type);
		}
		[str appendString:@"}, "];
	}
	//TODO: show where unused bytes appear in structure
	//They won't just appear at the end!
#if 0
	while (offset < self.size) {
		//Append X (ie unused byte)
		[str appendString:@"X"];
		offset++;
	}
#endif

	[str appendString:@"}"];
	return str;
}

- (NSString *)description;
{
	return [NSString stringWithFormat:@"<%@ : %p size:%d aligned:%d fields:%d>", [self class], self, size, self.size, fieldCount];
}

- (void)enumerateFieldsWithBlock:(void( (^)(NSUInteger idx, const WMStructureField *field, NSUInteger offset)))inBlock;
{
	if (!inBlock) return;
	for (int i=0; i<fieldCount; i++) {
		inBlock(i, &fields[i], fields[i].offset);
	}
}

- (BOOL)getFieldNamed:(NSString *)inField outField:(WMStructureField *)outField;
{
	char inName[256];
	BOOL ok = [inField getCString:inName maxLength:255 encoding:NSASCIIStringEncoding];
	if (ok) {
		for (int i=0; i<fieldCount; i++) {
			if (strncmp(inName, fields[i].name, 255) == 0) {
				if (outField)  *outField = fields[i];
				return YES;
			}
		}
	}
	return NO;
}

@end
