//
//  WMNumberPort.m
//  Particulon
//
//  Created by Andrew Pouliot on 4/19/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMNumberPort.h"


@implementation WMNumberPort
@synthesize value;

- (id)stateValue;
{
	return [NSNumber numberWithDouble:value];
}

- (BOOL)setStateValue:(id)inStateValue;
{
	@try {
		self.value = [inStateValue doubleValue];
		return YES;
	}
	@catch (NSException *exception) {
		return NO;
	}
}

- (BOOL)takeValueFromPort:(WMPort *)inPort;
{
	if ([inPort isKindOfClass:[WMNumberPort class]]) {
		WMNumberPort *sourcePort = (WMNumberPort *)inPort;
		self.value = sourcePort.value;
		return YES;
	} else {
		return NO;
	}
}

@end
