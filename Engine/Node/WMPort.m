//
//  WMPort.m
//  Particulon
//
//  Created by Andrew Pouliot on 4/19/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMPort.h"


@implementation WMPort
@synthesize key;
@synthesize name;
@synthesize originalPort;

- (id)stateValue;
{
	return nil;
}

- (BOOL)setStateValue:(id)inStateValue;
{
	return YES;
}

- (BOOL)takeValueFromPort:(WMPort *)inPort;
{
	return YES;
}

- (BOOL)canTakeValueFromPort:(WMPort *)inPort;
{
	return [[inPort class] isEqual:[self class]];
}

- (NSString *)description;
{
	NSString *origStr = originalPort ? [NSString stringWithFormat:@" orig:%@", originalPort.name] : @"";
	return [NSString stringWithFormat:@"<%@ : %p>{key: %@, state:%@%@}", NSStringFromClass([self class]), self, self.key, [self stateValue], origStr];
}

@end
