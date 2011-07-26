//
//  WMVectorPort.m
//  WMEdit
//
//  Created by Andrew Pouliot on 7/25/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMVectorPort.h"

#import "WMRenderCommon.h"

@implementation WMVectorPort  {
@protected
	GLKVector4 _v;
	int _size;
}

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (id)stateValue;
{
	return [NSValue valueWithBytes:&_v objCType:@encode(GLKVector4)];
}

- (BOOL)setStateValue:(id)inStateValue;
{
	if ([inStateValue isKindOfClass:[NSValue class]]) {
		if (strcmp([inStateValue objCType], @encode(GLKVector4)) == 0) {
			_v = *(GLKVector4 *)[inStateValue bytes];
			return YES;
		}
	}
	return NO;
}

- (BOOL)takeValueFromPort:(WMPort *)inPort;
{
	if ([inPort isKindOfClass:[WMVectorPort class]]) {
		WMVectorPort *inVectorPort = (WMVectorPort *)inPort;
		_v = inVectorPort->_v;
		return YES;
	} else {
		//TODO: coersion
		return NO;
	}
}

//Vector ports can take any vector port's values
- (BOOL)canTakeValueFromPort:(WMPort *)inPort;
{
	return [inPort isKindOfClass:[WMVectorPort class]];
}

@end


@implementation WMVector2Port

- (id)init;
{
    if (!(self = [super init])) return nil;
	_size = 2;
    return self;
}

- (GLKVector2)v;
{
	return (GLKVector2){_v.x, _v.y};
}

- (void)setV:(GLKVector2)inV;
{
	_v = (GLKVector4){inV.x, inV.y, 0.0f, 0.0f};
}

- (NSString *)description;
{
	return [NSString stringWithFormat:@"<%@ : %p>{key: %@, v:%@}", NSStringFromClass([self class]), self, self.key, NSStringFromGLKVector2(self.v)];
}

@end


@implementation WMVector3Port

- (id)init;
{
    if (!(self = [super init])) return nil;
	_size = 3;
    return self;
}

- (GLKVector3)v;
{
	return (GLKVector3){_v.x, _v.y, _v.z};
}

- (void)setV:(GLKVector3)inV;
{
	_v = (GLKVector4){inV.x, inV.y, inV.z, 0.0f};
}

- (NSString *)description;
{
	return [NSString stringWithFormat:@"<%@ : %p>{key: %@, v:%@}", NSStringFromClass([self class]), self, self.key, NSStringFromGLKVector3(self.v)];
}

@end


@implementation WMVector4Port

- (id)init;
{
    if (!(self = [super init])) return nil;
	_size = 4;
    return self;
}

- (GLKVector4)v;
{
	return _v;
}

- (void)setV:(GLKVector4)inV;
{
	_v = inV;
}

- (NSString *)description;
{
	return [NSString stringWithFormat:@"<%@ : %p>{key: %@, v:%@}", NSStringFromClass([self class]), self, self.key, NSStringFromGLKVector4(self.v)];
}

@end