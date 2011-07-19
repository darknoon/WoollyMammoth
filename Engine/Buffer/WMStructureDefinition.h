//
//  WMStructureDefinition.h
//  WMViewer
//
//  Created by Andrew Pouliot on 7/10/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

//Same enum values as their OpenGL ES equivalents
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
	/* const */ char name[256]; //Name must be less than 256 bytes ASCII
	WMStructureType type;
	BOOL normalized;
	int count;
} WMStructureField;

//Size of the data backing this field ie 4 x float = 4 x 4 bytes = 16
extern size_t WMStructureFieldSize(WMStructureField inField);
extern size_t WMStructureTypeSize(WMStructureType inType);



@interface WMStructureDefinition : NSObject

//This must follow the same structure as @encode in objective C
//TODO: allow specification of alignment (ie, how large it should pad out to)
- (id)initWithFields:(const WMStructureField *)inFields count:(NSUInteger)inCount;

- (id)initWithAnonymousFieldOfType:(WMStructureType)inType;

//If yes, you don't need to ask about fields, it's just a single type (ie, single field with count = 1)
@property (nonatomic, readonly) BOOL isSingleType;

//Default is NO. If YES, additional empty bytes are added to pad out the structure.
@property (nonatomic) BOOL shouldAlignTo4ByteBoundary;

@property (nonatomic, readonly) NSUInteger size;

//-1 = not found
- (NSInteger)offsetOfField:(NSString *)inField;
- (NSInteger)sizeOfField:(NSString *)inField;

//TODO: - (BOOL)getValueOfField:(NSString *)inField asType:(WMStructureType)inOutputType outBytes:(void *)outPtr;

- (NSString *)descriptionOfData:(const void *)inData;

- (BOOL)getFieldNamed:(NSString *)inName outField:(WMStructureField *)outField outOffset:(NSUInteger *)outOffset;

@end
