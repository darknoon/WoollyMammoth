//
//  WMIndexPort.m
//  Particulon
//
//  Created by Andrew Pouliot on 4/19/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMIndexPort.h"


@implementation WMIndexPort
@synthesize index;

- (BOOL)setObjectValue:(id)inRuntimeValue;
{
	@try {
		self.index = [inRuntimeValue unsignedIntegerValue];
		return YES;
	}
	@catch (NSException *exception) {
		return NO;
	}
}

- (id)objectValue;
{
	return [NSNumber numberWithUnsignedInteger:index];
}

- (BOOL)takeValueFromPort:(WMPort *)inPort;
{
	if ([inPort isKindOfClass:[WMIndexPort class]]) {
		WMIndexPort *sourcePort = (WMIndexPort *)inPort;
		self.index = sourcePort.index;
		return YES;
	} else {
		return NO;
	}
}


@end
