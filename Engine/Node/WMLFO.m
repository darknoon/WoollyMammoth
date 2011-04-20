//
//  WMLFO.m
//  Particulon
//
//  Created by Andrew Pouliot on 4/19/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMLFO.h"

#import "WMIndexPort.h"
#import "WMNumberPort.h"

@implementation WMLFO

+ (void)load;
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[self registerToRepresentClassNames:[NSSet setWithObject:@"QCLFO"]];
	[pool drain];
}

- (BOOL)execute:(WMEAGLContext *)inContext time:(CFTimeInterval)time arguments:(NSDictionary *)args;
{
	//Calculate the output value;
	switch (inputType.index) {
		case WMLFOTypeSin:
			outputValue.value = inputAmplitude.value * sinf(time / inputPeriod.value * 2.f * M_PI + inputPhase.value) + inputOffset.value;
			return YES;
		case WMLFOTypeCos:
			outputValue.value = inputAmplitude.value * cosf(time / inputPeriod.value * 2.f * M_PI + inputPhase.value) + inputOffset.value;
			return YES;
		default:
			NSLog(@"invalid lfo type: %d", inputType.index);
			return NO;
	}
	
}

@end
