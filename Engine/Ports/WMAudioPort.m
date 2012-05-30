//
//  WMAudioPort.m
//  WMEdit
//
//  Created by Andrew Pouliot on 5/28/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import "WMAudioPort.h"
#import "WMAudioBuffer.h"

@implementation WMAudioPort
@synthesize buffer = _buffer;

- (BOOL)isInputValueTransient;
{
	return YES;
}

- (id)stateValue;
{
	return nil;
}

- (BOOL)setStateValue:(id)inStateValue;
{
	return NO;
}

- (id)objectValue;
{
	return _buffer;
}

- (BOOL)setObjectValue:(id)inRuntimeValue;
{
	if (!inRuntimeValue || [inRuntimeValue isKindOfClass:WMAudioBuffer.class]) {
		_buffer = inRuntimeValue;
		return YES;
	} else {
		return NO;
	}
}

- (BOOL)takeValueFromPort:(WMPort *)inPort;
{
	id value = inPort.objectValue;
	if (!value || [value isKindOfClass:WMAudioBuffer.class]) {
		self.objectValue = inPort.objectValue;
		return YES;		
	} else {
		return NO;
	}
}

//For now no conversion between float buffers and audio buffers
- (BOOL)canTakeValueFromPort:(WMPort *)inPort;
{
	return [inPort isKindOfClass:self.class];
}

@end
