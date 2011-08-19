//
//  WMStringPort.m
//  VideoLiveEffect
//
//  Created by Andrew Pouliot on 5/22/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMStringPort.h"


@implementation WMStringPort
@synthesize value;


- (id)objectValue;
{
	return value;
}

- (BOOL)setObjectValue:(id)inRuntimeValue;
{
	if ([inRuntimeValue isKindOfClass:[NSString class]]) {
		self.value = (NSString *)inRuntimeValue;
		return YES;
	}
	return NO;
}

- (BOOL)takeValueFromPort:(WMPort *)inPort;
{
	if ([inPort isKindOfClass:[WMStringPort class]]) {
		self.value = [(WMStringPort *)inPort value];
		return YES;
	}
	return NO;
}

- (NSString *)description;
{
	NSString *origStr = self.originalPort ? [NSString stringWithFormat:@" orig:%@", self.originalPort.name] : @"";
	return [NSString stringWithFormat:@"<%@ : %p>{key: %@, state:%@%@}", NSStringFromClass([self class]), self, self.key, [self stateValue], origStr];
}

@end
