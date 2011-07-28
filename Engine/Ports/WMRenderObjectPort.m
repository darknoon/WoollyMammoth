//
//  Created by Andrew Pouliot on 7/27/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMRenderObjectPort.h"

@implementation WMRenderObjectPort
@synthesize object;

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
