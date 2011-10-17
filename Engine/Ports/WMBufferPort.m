//
//  WMBufferPort.m
//  WMEdit
//
//  Created by Andrew Pouliot on 10/15/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import "WMBufferPort.h"

#import "WMStructuredBuffer.h"

@implementation WMBufferPort
@synthesize object;

- (id)objectValue;
{
	return self.object;
}


//We can't be serialized, so there is no value here
- (id)stateValue;
{
	return nil;
}

- (BOOL)setStateValue:(id)inStateValue;
{
	return NO;
}

- (BOOL)setObjectValue:(id)inRuntimeValue;
{
	if ([inRuntimeValue isKindOfClass:[WMStructuredBuffer class]]) {
		self.object = inRuntimeValue;
		return YES;
	}
	return NO;
}

- (BOOL)takeValueFromPort:(WMPort *)inPort;
{
	if ([inPort isKindOfClass:[WMBufferPort class]]) {
		WMBufferPort *otherPort = (WMBufferPort *)inPort;
		self.object = otherPort.object;
		return YES;
	}
	return NO;
}

@end
