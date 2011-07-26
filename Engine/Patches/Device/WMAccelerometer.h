//
//  WMAccelerometer.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 12/4/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMRenderCommon.h"

#import "WMPatch.h"
#import "WMPort.h"

@interface WMAccelerometer : WMPatch {
	
	//TODO: replace with vector output ports
	
	WMVector3Port *outputAcceleration;
	WMVector3Port *outputGravity;
	WMVector3Port *outputRotationRate;	
}

@end
