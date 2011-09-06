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

+ (id)portWithKey:(NSString *)inKey;
{
	WMPort *p = [[[self class] alloc] init];
	p.key = inKey;
	return p;
}

- (NSString *)name;
{
	return name ? name : key;
}

//Default implementations use the runtime values, but should be overriden to provide plist-compatible values
- (id)stateValue;
{
	return [self objectValue];
}

- (BOOL)setStateValue:(id)inStateValue;
{
	return [self setObjectValue:inStateValue];
}

- (BOOL)takeValueFromPort:(WMPort *)inPort;
{
	return YES;
}

- (id)objectValue;
{
	return nil;
}

- (BOOL)setObjectValue:(id)inRuntimeValue;
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
