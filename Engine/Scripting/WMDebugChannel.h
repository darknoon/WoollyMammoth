//
//  WMDebugChannel.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/12/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>


@class AsyncSocket;
@class WMEngine;

@interface WMDebugChannel : NSObject {
	WMEngine *engine;
	
	UInt16 listenPort;
	AsyncSocket *listenSocket;

	NSMutableSet *debugSockets;
}

- (id)initWithEngine:(WMEngine *)inEngine onPort:(UInt16)inListenPort;

@property (nonatomic, readonly) WMEngine *engine;

- (void)broadcastMessageToSockets:(NSString *)inMessage;

- (void)start;

@end
