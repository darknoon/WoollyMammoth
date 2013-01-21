//
//  Created by Andrew Pouliot on 7/10/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

//Same enum values as their OpenGL ES equivalents
//A vec4 is just 4 floats as far as the structured buffer is concerned
typedef enum {
	WMStructureTypeByte           = 0x1400,
	WMStructureTypeUnsignedByte,
	WMStructureTypeShort,
	WMStructureTypeUnsignedShort,
	WMStructureTypeInt,
	WMStructureTypeUnsignedInt,
	WMStructureTypeFloat,
	//Double is not currently supported
	//WMStructureTypeDouble, 
	
	/*
	 TODO: Should we support vec4f[4] or just f[16] ?
	 */
	
	//Same as GL_FIXED
	WMStructureTypeFixed = 0x140C,
	
} WMStructureType;

typedef struct {
	char name[256];  //Name must be less than 256 bytes ASCII
	WMStructureType type;  //The underlying data type of the data GLKVector3 = WMStructureTypeFloat
	unsigned int count;    //The count of this underlying type    GLKVector3 = 3
	size_t offset;         //The offset in the input data. If you have a c struct, use offsetof(struct, name) to get this
	BOOL normalized;       //Normalized = map the interval [<minimum of this type>, <maximum of this type>] to [0, 1]. For example, a texture coord can be packed into a byte
} WMStructureField;

//Size of the data backing this field ie 4 x float = 4 x 4 bytes = 16
extern size_t WMStructureFieldSize(WMStructureField inField);

//Size of one element of this field ie float = 4 bytes
extern size_t WMStructureTypeSize(WMStructureType inType);

/**
 @abstract Defines metadata about a structured buffer
 @discussion 
 */
@interface WMStructureDefinition : NSObject

/**
 @abstract Create a structured buffer from a C array of fields.
 @discussion The total size must be provided, as the alignment requirements of the struct may require.
 */
- (id)initWithFields:(const WMStructureField *)inFields count:(NSUInteger)inCount totalSize:(size_t)totalSize;

/**
 @abstract Create a structured buffer with a single field type
 @discussion This is useful for any buffer with a single type of data like int[], unsigned short[], etc.
 */
- (id)initWithAnonymousFieldOfType:(WMStructureType)inType;

/**
 @abstract Whether the buffer is of type X[] rather than struct{X, Y, S}[]
 @discussion If yes, you don't need to ask about fields, it's just a single type (ie, single field with count = 1)
 */
@property (nonatomic, readonly) BOOL isSingleType;

/**
 @abstract Whether to pad the structure to a multiple of 4 bytes
 @discussion Default is NO. If set to YES, additional empty bytes are added to pad out the structure if needed. Your compiler may have already done this for you if you used sizeof(struct blah) */
@property (nonatomic) BOOL shouldAlignTo4ByteBoundary;

/**
 @abstract The total size of the represented structure
 */
@property (nonatomic, readonly) NSUInteger size;

/**
 @abstract Get the offset of a named field in the structure
 @param field The name of a field
 @returns offset in bytes or -1 if not found
 */
- (NSInteger)offsetOfField:(NSString *)field;

/**
 @abstract Get the size of a named field in the structure
 @param field The name of a field
 @returns Size in bytes or -1 if not found
 */
- (NSInteger)sizeOfField:(NSString *)field;

//TODO: - (BOOL)getValueOfField:(NSString *)inField asType:(WMStructureType)inOutputType outBytes:(void *)outPtr;

/**
 @abstract A sort of souped-up description for structured data
 @param data The raw data to describe, when interpreted as being in the format of the reciever. data must contain at least size bytes.
 @returns A string describing the values in the data, suitable for debugging.
 */
- (NSString *)descriptionOfData:(const void *)data;

/**
 @abstract Get all info about a field in the structure
 @param field The name of a field
 @param outField A pointer to write the field struct into
 @returns Whether the field was found in the structure definition. If NO is returned, the contents of outField are undefined.
 */
- (BOOL)getFieldNamed:(NSString *)field outField:(WMStructureField *)outField;

/**
 @abstract Get all info about a field in the structure
 @param field The name of a field as a C string
 @param outField A pointer to write the field struct into
 @returns Whether the field was found in the structure definition. If NO is returned, the contents of outField are undefined.
 */
- (BOOL)getFieldNamedUTF8:(const char *)fieldCString outField:(WMStructureField *)outField;


@end
