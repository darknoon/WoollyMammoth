//
//  WMTransformPort.m
//  Take
//
//  Created by Andrew Pouliot on 11/28/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import "WMTransformPort.h"

@implementation WMTransformPort

- (id)init;
{
    self = [super init];
    if (!self) return nil;
	
	_v = GLKMatrix4Identity;
    
    return self;
}


- (BOOL)setObjectValue:(id)runtimeValue;
{
	if ([runtimeValue isKindOfClass:[NSValue class]]) {
		NSValue *value = (NSValue *)runtimeValue;
		if ([value containsGLKMatrix4]) {
			_v = [value GLKMatrix4Value];
			return YES;
		}
	}
	return NO;
}

- (id)objectValue;
{
	return [NSValue valueWithGLKMatrix4:_v];
}

- (BOOL)takeValueFromPort:(WMPort *)port;
{
	if ([port isKindOfClass:[WMTransformPort class]]) {
		WMTransformPort *sourcePort = (WMTransformPort *)port;
		self.v = sourcePort.v;
		return YES;
	} else {
		return NO;
	}
}

@end
