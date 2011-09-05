//
//  WMMIDIReciever.m
//  WMViewer
//
//  Created by Andrew Pouliot on 4/26/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMMIDIReciever.h"

#import "PGMidi.h"
#import "PGMidiAllSources.h"

@implementation WMMIDIReciever

+ (NSString *)category;
{
    return WMPatchCategoryDevice;
}

+ (NSString *)humanReadableTitle {
    return @"Midi Controller";
}

+ (void)load;
{
	@autoreleasepool {
		[self registerPatchClass];
	}
}

- (BOOL)setPlistState:(id)inPlist;
{
	BOOL ok = [super setPlistState:inPlist];
	if (ok) {
		//TODO: read channel mask
		
		channelMask = 1<<1 | 1<<2 | 1<<3;
				
//		NSData *channelMaskData = [inPlist objectForKey:@"controllers"];
//		if (channelMaskData.length > sizeof(unsigned long) + 3) {
//			const void *channelMaskPtr = [channelMaskData bytes];
//			//TODO: endian safe math
//			channelMask = OSReadBigInt64(channelMaskPtr, 3);
//		}
		
		for (int i=0; i<120; i++) {
			if (channelMask & 1<<i) {
				WMNumberPort *outputPort = [[WMNumberPort alloc] init];
				outputPort.name = [NSString stringWithFormat:@"controller_%d", i];
				[self addOutputPort:outputPort];
			}
		}
	}
	return ok;
}

- (BOOL)setup:(WMEAGLContext *)context;
{
	midi = [[PGMidi alloc] init];
	[midi enableNetwork:YES];

	for (PGMidiSource *source in midi.sources) {
		source.delegate = (NSObject<PGMidiSourceDelegate> *)self;
	}
	
	//Initial calls won't hit this
	midi.delegate = (NSObject<PGMidiDelegate> *)self;
	
	return YES;
}

- (void) midi:(PGMidi*)inMidi sourceAdded:(PGMidiSource *)source;
{
	NSLog(@"+ Midi sources: %@", [inMidi sources]);
}
- (void) midi:(PGMidi*)inMidi sourceRemoved:(PGMidiSource *)source;
{
	NSLog(@"- Midi sources: %@", [inMidi sources]);	
}
- (void) midi:(PGMidi*)midi destinationAdded:(PGMidiDestination *)destination;
{
	NSLog(@"Destinations changed");
}
- (void) midi:(PGMidi*)midi destinationRemoved:(PGMidiDestination *)destination;
{
	NSLog(@"Destinations changed");
}


//BACKGROUND THREAD!!
- (void) midiSource:(PGMidiSource*)input midiReceived:(const MIDIPacketList *)packetList;
{
	@autoreleasepool {
	
		dispatch_queue_t mainQueue = dispatch_get_main_queue();
		const MIDIPacket *packet = &packetList->packet[0];
		for (int i=0; i<packetList->numPackets; i++) {
//			NSData *dat = [[NSData alloc] initWithBytes:packet->data length:packet->length];
//		NSLog(@"midi packet: %@", dat);
			//TODO: put in some real MIDI packet parsing here!
			for (int byte = 0; byte < packet->length; byte++) {
				//Take control data only
				unsigned char statusByte = packet->data[byte++];
				unsigned char msgType = statusByte & 0xf0;
				if (msgType == 0xb0) {
					//Read control number
					char controlNumber = packet->data[byte++];
					char value = (int)packet->data[byte++];
//				NSLog(@"midi control change number %d = %d (%f)", (int)controlNumber, (int)value, value / 127.f);
					if (controlNumber < 120) { //Numbers above 120 are reserved
						dispatch_async(mainQueue, ^{
							WMNumberPort *outputPort = (WMNumberPort *)[self outputPortWithKey:[NSString stringWithFormat:@"controller_%d", controlNumber]];
							outputPort.value = value / 127.f;
						});
					}
				} else {
//				NSLog(@"unknown type %c", msgType);
					//TODO: correctly handle other data sizes so we can get control data in the same packet
					break;
				}
			}
			
			packet = MIDIPacketNext(packet);
		}
	}
}


- (BOOL)execute:(WMEAGLContext *)context time:(double)time arguments:(NSDictionary *)args;
{
	return YES;
}

@end
