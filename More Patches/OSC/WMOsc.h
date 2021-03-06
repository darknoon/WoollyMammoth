//
//  WMOsc.m
//  Tr3Osc
//
//  Created by Warren Stringer on 7/16/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <WMGraph/WMGraph.h>
#import "OscReceiver.h"


@interface WMOsc : WMPatch {

    OscReceiver	_receiver;

	WMNumberPort *outputAccelX;
	WMNumberPort *outputAccelY;
	WMNumberPort *outputAccelZ;
}

@end
