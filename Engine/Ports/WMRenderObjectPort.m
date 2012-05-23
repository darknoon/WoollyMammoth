//
//  Created by Andrew Pouliot on 7/27/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMRenderObjectPort.h"
#import "WMRenderObject.h"

@implementation WMRenderObjectPort
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

- (BOOL)isInputValueTransient;
{
	return YES;
}

- (BOOL)setObjectValue:(id)inRuntimeValue;
{
	if (!inRuntimeValue || [inRuntimeValue isKindOfClass:[WMRenderObject class]]) {
		self.object = inRuntimeValue;
		return YES;
	}
	return NO;
}

- (BOOL)takeValueFromPort:(WMPort *)inPort;
{
	if ([inPort isKindOfClass:[WMRenderObjectPort class]]) {
		WMRenderObjectPort *otherPort = (WMRenderObjectPort *)inPort;
		self.object = otherPort.object;
		return YES;
	}
	return NO;
}

@end
