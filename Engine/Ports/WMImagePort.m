//
//  WMImagePort.m
//  Particulon
//
//  Created by Andrew Pouliot on 4/19/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMImagePort.h"

#import "WMTexture2D.h"

@implementation WMImagePort
@synthesize image;

//We can't be serialized, so there is no value here
- (id)stateValue;
{
	return nil;
}

- (BOOL)setStateValue:(id)inStateValue;
{
	return NO;
}

- (BOOL)takeValueFromPort:(WMPort *)inPort;
{
	if ([inPort isKindOfClass:[WMImagePort class]]) {
		self.image = [(WMImagePort *)inPort image];
		return YES;
	} else {
		return NO;
	}
}

- (NSString *)description;
{
	return [NSString stringWithFormat:@"<%@ : %p>{texture: %@}", NSStringFromClass([self class]), self, image];
}

@end
