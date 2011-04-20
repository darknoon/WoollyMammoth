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
	return [NSString stringWithFormat:@"<%@ : %p>{name: %@, state:%@}", NSStringFromClass([self class]), self, self.name, [self stateValue]];
}

@end
