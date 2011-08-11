//
//  WMSphere.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 12/6/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMPatch.h"

//Should render a nice sphere. Right now does a janky one :P
@interface WMSphere : WMPatch {	
	
	WMIndexPort *inputUCount;
	WMIndexPort *inputVCount;
	WMNumberPort *inputRadius;
//	WMNumberPort *inputRhoStart;
//	WMNumberPort *inputRhoEnd;
//	WMNumberPort *inputPhiStart;
//	WMNumberPort *inputPhiEnd;
		
	WMRenderObjectPort *outputSphere;
}

@end
