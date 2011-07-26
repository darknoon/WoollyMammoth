//
//  WMColorFromComponents.h
//  Particulon
//
//  Created by Andrew Pouliot on 4/19/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMPatch.h"

@class WMNumberPort;
@class WMColorPort;

enum WMColorFromComponentsMode {
	WMColorFromComponentsHSL,
	WMColorFromComponentsRGB,
};

@interface WMColorFromComponents : WMPatch {
	WMNumberPort *input1;
	WMNumberPort *input2;
	WMNumberPort *input3;
	WMNumberPort *inputAlpha;
	WMColorPort *outputColor;
	int mode;
}

@end
