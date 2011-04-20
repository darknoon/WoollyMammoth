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

- (id)stateValue;
{
	return [NSNumber numberWithBool:value];
}

- (BOOL)setStateValue:(id)inStateValue;
{
	@try {
		self.value = [inStateValue boolValue];
		return YES;
	}
	@catch (NSException *exception) {
		return NO;
	}
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
