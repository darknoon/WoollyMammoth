//
//  WMLFO.h
//  Particulon
//
//  Created by Andrew Pouliot on 4/19/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMPatch.h"
@class WMNumberPort;
@class WMIndexPort;

//Compatible with QC
enum {
	WMLFOTypeSin = 0,
	WMLFOTypeCos,
	WMLFOTypeTriangle,
	WMLFOTypeSquare,
	WMLFOTypeSawtoothUp,
	WMLFOTypeSawtoothDown,
	WMLFOTypeUndefined,
};
typedef NSUInteger WMLFOType;

@interface WMLFO : WMPatch {
	WMIndexPort *inputType;
	WMNumberPort *inputPeriod;
	WMNumberPort *inputPhase;
	WMNumberPort *inputAmplitude;
	WMNumberPort *inputOffset;
//	WMNumberPort *inputPWMRatio;
	WMNumberPort *outputValue;
}

@end
