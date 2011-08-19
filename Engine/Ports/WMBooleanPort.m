//
//  WMBooleanPort.m
//  Particulon
//
//  Created by Andrew Pouliot on 4/19/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMBooleanPort.h"


@implementation WMBooleanPort
@synthesize value;

- (id)objectValue;
{
	return [NSNumber numberWithBool:value];
}

- (BOOL)setObjectValue:(id)inRuntimeValue;
{
	if ([inRuntimeValue isKindOfClass:[NSNumber class]]) {
		self.value = [inRuntimeValue boolValue];
		return YES;
	}
	return NO;
}

- (BOOL)takeValueFromPort:(WMPort *)inPort;
{
	if ([inPort isKindOfClass:[WMBooleanPort class]]) {
		WMBooleanPort *sourcePort = (WMBooleanPort *)inPort;
		self.value = sourcePort.value;
		return YES;
	} else {
		return NO;
	}
}


@end
