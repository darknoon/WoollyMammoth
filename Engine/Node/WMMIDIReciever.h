//
//  WMMIDIReciever.h
//  WMViewer
//
//  Created by Andrew Pouliot on 4/26/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMPatch.h"

@class PGMidi;
@class PGMidiAllSources;
@interface WMMIDIReciever : WMPatch {
	PGMidi *midi;
	unsigned long channelMask;
}

@end
