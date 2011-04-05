//
//  WMDebugChannel.m
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/12/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import "WMDebugChannel.h"

#import "AsyncSocket.h"
#import "WMEngine.h"
#import "WMGameObject.h"
#import "WMScriptingContext.h"

@interface WMDebugChannel ()
- (void)processCommand:(NSString *)inCommand onSocket:(AsyncSocket *)inSocket;
@end


@implementation WMDebugChannel

@synthesize engine;

- (id)initWithEngine:(WMEngine *)inEngine onPort:(UInt16)inListenPort;
{
	self = [self init];
	if (self == nil) return self; 
	
	engine = inEngine;
	listenPort = inListenPort;
	listenSocket = [[AsyncSocket alloc] initWithDelegate:self];
	debugSockets = [[NSMutableSet alloc] init];
	
	return self;
}

- (void)start;
{
	NSError *error = nil;
	if (![listenSocket acceptOnPort:listenPort error:&error]) {
		NSLog(@"Error starting debug channel: %@", error);
	} else {
		NSLog(@"Started debug channel on %@:%d", [listenSocket localAddress], listenPort);
	}

}


- (void)processCommand:(NSString *)inCommand onSocket:(AsyncSocket *)inSocket;
{
	inCommand = [inCommand stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	NSLog(@"Recieved command: %@", inCommand);
	
	//Execute the command as lua!
	[engine.scriptingContext doScript:inCommand];
	
	//Any output will (currently?) be broadcast to all debug channels
}

- (void)broadcastMessageToSockets:(NSString *)inMessage;
{
	for (AsyncSocket *debugSocket in debugSockets) {
		[debugSocket writeData:[inMessage dataUsingEncoding:NSUTF8StringEncoding] withTimeout:10.0 tag:0];
	}
}

- (void)readCommand:(AsyncSocket *)inSocket;
{
	[inSocket readDataToData:[AsyncSocket CRLFData] withTimeout:1000000.0 tag:0];
}

- (void)onSocket:(AsyncSocket *)inSocket didReadData:(NSData *)inData withTag:(long)inTag;
{
	NSString *command = [[[NSString alloc] initWithData:inData encoding:NSUTF8StringEncoding] autorelease];
	[self processCommand:command onSocket:inSocket];
	//Schedule next command read
	[self readCommand:inSocket];
}

- (void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket;
{
	[self readCommand:newSocket];
}

- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port;
{
	NSLog(@"Accepted new debugger client from %@ on port %d.", host, listenPort);
	[debugSockets addObject:sock];

}

- (void)onSocketDidDisconnect:(AsyncSocket *)sock;
{
	NSLog(@"Debugger client %@ disconnected", [sock connectedHost]);
	[debugSockets removeObject:sock];

}

- (void) dealloc
{
	[listenSocket release], listenSocket = nil;
	

	[super dealloc];
}


@end
