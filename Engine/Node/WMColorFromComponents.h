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
	WMNumberPort *input1;	// 156 = 0x9c
	WMNumberPort *input2;	// 160 = 0xa0
	WMNumberPort *input3;	// 164 = 0xa4
	WMNumberPort *inputAlpha;	// 168 = 0xa8
	WMColorPort *outputColor;	// 172 = 0xac
	int mode;	// 176 = 0xb0
}

@end
