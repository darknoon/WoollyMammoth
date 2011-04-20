//
//  WMColorPort.m
//  Particulon
//
//  Created by Andrew Pouliot on 4/19/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMColorPort.h"


@implementation WMColorPort
@synthesize red;
@synthesize green;
@synthesize blue;
@synthesize alpha;

- (id)stateValue;
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithFloat:self.red], @"red",
			[NSNumber numberWithFloat:self.green], @"green",
			[NSNumber numberWithFloat:self.blue], @"blue",
			[NSNumber numberWithFloat:self.alpha], @"alpha",
			nil];
}

- (BOOL)setStateValue:(id)inStateValue;
{
	if (![inStateValue isKindOfClass:[NSDictionary class]]) {
		return NO;
	}
	@try {
		self.red = [[inStateValue objectForKey:@"red"] floatValue];
		self.green = [[inStateValue objectForKey:@"green"] floatValue];
		self.blue = [[inStateValue objectForKey:@"blue"] floatValue];
		self.alpha = [[inStateValue objectForKey:@"alpha"] floatValue];
		return YES;
	}
	@catch (NSException *exception) {
		return NO;
	}

}

- (BOOL)takeValueFromPort:(WMPort *)inPort;
{
	if ([inPort isKindOfClass:[WMColorPort class]]) {
		WMColorPort *sourcePort = (WMColorPort *)inPort;
		self.red = sourcePort.red;
		self.green = sourcePort.green;
		self.blue = sourcePort.blue;
		self.alpha = sourcePort.alpha;
		return YES;
	} else {
		return NO;
	}
}

- (NSString *)description;
{
	return [NSString stringWithFormat:@"<%@ : %p>{r:%f g:%f b:%f, a:%f}", NSStringFromClass([self class]), self, red, green, blue, alpha];
}


@end
