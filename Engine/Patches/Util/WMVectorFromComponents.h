//
//  WMVectorFromComponents.h
//  WMEdit
//
//  Created by Andrew Pouliot on 7/26/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMPatch.h"

@interface WMVectorFromComponents : WMPatch {
	WMNumberPort *inputX;
	WMNumberPort *inputY;
	WMNumberPort *inputZ;
	WMNumberPort *inputW;
	
	WMVector4Port *outputPort;
}

@end
