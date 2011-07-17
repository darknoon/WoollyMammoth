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
- (BOOL)setup:(WMEAGLContext *)context;
{
	inputPeriod.value    = 1;
	inputPhase.value     = 0.;
	inputAmplitude.value = 1.;
	inputOffset.value    = 0.;
}
- (BOOL)execute:(WMEAGLContext *)inContext time:(CFTimeInterval)time arguments:(NSDictionary *)args;
{
	//Calculate the output value;
	float a = inputAmplitude.value;
	float p = inputPeriod.value;
	float o = inputPhase.value;
	float c = inputOffset.value;
		
	float temp;
	switch (inputType.index) {
		case WMLFOTypeSin:
			outputValue.value = a * sinf(time / p * 2.f * M_PI - o) + c;
			return YES;
		case WMLFOTypeCos:
			outputValue.value = a * cosf(time / p * 2.f * M_PI - o) + c;
			return YES;
		case WMLFOTypeTriangle:
			temp = 2 * (time - o) / p;
			outputValue.value = a * fabsf(1.f + 2.f*(floorf(temp) - temp)) - a/2.f + c;
			return YES;
		case WMLFOTypeSquare:
			temp = 2 * (time - o) / p;
			outputValue.value = floorf(temp) + 0.5f - temp > 0.f ? 1.f : -1.f;
			return YES;
		case WMLFOTypeSawtoothUp:
			temp = 2 * (time - o) / p;
			outputValue.value = a * -(1.f + 2.f*(floorf(temp) - temp)) + c;
			return YES;
		case WMLFOTypeSawtoothDown:
			temp = (time - inputPhase.value) / inputPeriod.value;
			outputValue.value = a * (1.f + 2.f*(floorf(temp) - temp)) + c;
			return YES;
		default:
			NSLog(@"invalid lfo type: %d", inputType.index);
			return NO;
	}
	
}

@end
