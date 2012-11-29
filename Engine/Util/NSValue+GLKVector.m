//
//  NSValue+GLKVector.m
//  WMEdit
//
//  Created by Andrew Pouliot on 7/28/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import "NSValue+GLKVector.h"

@implementation NSValue (GLKVector)

#define MAKE_INIT(type) \
- (id)initWith##type:(type)v; \
{\
	return [self initWithBytes:&v objCType:@encode(type)]; \
}\

MAKE_INIT(GLKVector4);
MAKE_INIT(GLKVector3);
MAKE_INIT(GLKVector2);


#define MAKE_VALUE_WITH(type) \
+ (id)valueWith##type:(type)v;\
{\
	return [self valueWithBytes:&v objCType:@encode(type)];\
}\

MAKE_VALUE_WITH(GLKVector4);
MAKE_VALUE_WITH(GLKVector3);
MAKE_VALUE_WITH(GLKVector2);


static BOOL isVector(const char *objCType) {
	if (strcmp(objCType, @encode(GLKVector4)) == 0) {
		return YES;
	} else if (strcmp(objCType, @encode(GLKVector3)) == 0) {
		return YES;
	} else if (strcmp(objCType, @encode(GLKVector2))  == 0) {
		return YES;
	}
	return NO;
}

- (BOOL)containsGLKVector;
{
	const char *objCType = [self objCType];
	return isVector(objCType);
}

- (GLKVector4)GLKVector4Value;
{
	GLKVector4 result = (GLKVector4){};
	const char *objCType = [self objCType];

	if (isVector(objCType)) {
		[self getValue:&result];
	}
	
	return result;
}

- (GLKVector3)GLKVector3Value;
{
	GLKVector4 result = (GLKVector4){};
	const char *objCType = [self objCType];
	
	if (isVector(objCType)) {
		[self getValue:&result];
	}
	
	return (GLKVector3){result.x, result.y, result.z};
}

- (GLKVector2)GLKVector2Value;
{
	GLKVector4 result = (GLKVector4){};
	const char *objCType = [self objCType];
	
	if (isVector(objCType)) {
		[self getValue:&result];
	}
	
	return (GLKVector2){result.x, result.y};
	
}


@end



@implementation NSValue (GLKMatrix)

MAKE_INIT(GLKMatrix4);
MAKE_VALUE_WITH(GLKMatrix4);

- (BOOL)containsGLKMatrix4;
{
	return strcmp(self.objCType, @encode(GLKMatrix4)) == 0;
}

- (GLKMatrix4)GLKMatrix4Value;
{
	if ([self containsGLKMatrix4]) {
		GLKMatrix4 matrix;
		[self getValue:&matrix];
		return matrix;
	}
	return GLKMatrix4Identity;
}

@end