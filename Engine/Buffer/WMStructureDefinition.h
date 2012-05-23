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

// to compile on 4.2, llvm 3.0 lion, 'const' had to be removed - acs
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



@interface WMStructureDefinition : NSObject

- (id)initWithFields:(const WMStructureField *)inFields count:(NSUInteger)inCount totalSize:(size_t)totalSize;

- (id)initWithAnonymousFieldOfType:(WMStructureType)inType;

//If yes, you don't need to ask about fields, it's just a single type (ie, single field with count = 1)
@property (nonatomic, readonly) BOOL isSingleType;

//Default is NO. If YES, additional empty bytes are added to pad out the structure if needed. Your compiler may have already done this for you.
@property (nonatomic) BOOL shouldAlignTo4ByteBoundary;

@property (nonatomic, readonly) NSUInteger size;

//-1 = not found
- (NSInteger)offsetOfField:(NSString *)inField;
- (NSInteger)sizeOfField:(NSString *)inField;

//TODO: - (BOOL)getValueOfField:(NSString *)inField asType:(WMStructureType)inOutputType outBytes:(void *)outPtr;

- (NSString *)descriptionOfData:(const void *)inData;

- (BOOL)getFieldNamed:(NSString *)inField outField:(WMStructureField *)outField;
- (BOOL)getFieldNamedUTF8:(const char *)inFieldName outField:(WMStructureField *)outField;


@end
