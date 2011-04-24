//
//  WMPort.m
//  Particulon
//
//  Created by Andrew Pouliot on 4/19/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMPort.h"


@implementation WMPort
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

- (NSString *)description;
{
	NSString *origStr = originalPort ? [NSString stringWithFormat:@" orig:%@", originalPort.name] : @"";
	return [NSString stringWithFormat:@"<%@ : %p>{name: %@, state:%@%@}", NSStringFromClass([self class]), self, self.name, [self stateValue], origStr];
}

@end
