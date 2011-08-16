//
//  WMPatchConnectionsView.m
//  WMEdit
//
//  Created by Andrew Pouliot on 7/16/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMPatchConnectionsView.h"

#import "WMPatch.h"
#import "WMConnection.h"
#import "WMConnectionView.h"
#import "WMGraphEditView.h"

#import "WMDraggingConnection.h"

@implementation WMPatchConnectionsView {
	NSMutableArray *connectionViews;
	
	NSMutableDictionary *draggingConnectionsByPatchKey;
	NSMutableDictionary *draggingConnectionViewsByPatchKey;
}
@synthesize rootPatch;
@synthesize graphView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    connectionViews = [[NSMutableArray alloc] init];
	
	draggingConnectionsByPatchKey = [[NSMutableDictionary alloc] init];
	draggingConnectionViewsByPatchKey = [[NSMutableDictionary alloc] init];
	return self;
}



- (void)reloadAllConnections;
{
	for (WMConnectionView *cv in connectionViews) {
		[cv removeFromSuperview];
	}
	[connectionViews removeAllObjects];
	
	for (WMConnection *connection in [rootPatch connections]) {
		WMConnectionView *view = [[WMConnectionView alloc] initWithFrame:CGRectZero];
		
		WMPatchView *startPatchView = [graphView patchViewForKey:connection.sourceNode];
		WMPatchView *endPatchView = [graphView patchViewForKey:connection.destinationNode];
		
		WMPatch *startPatch = [rootPatch patchWithKey:connection.sourceNode];
		WMPatch *endPatch = [rootPatch patchWithKey:connection.destinationNode];
		
		WMPort *startPort = [startPatch outputPortWithKey:connection.sourcePort];
		WMPort *endPort = [endPatch inputPortWithKey:connection.destinationPort];
		
		[self addSubview:view];
		view.startPoint = [startPatchView pointForOutputPort:startPort];
		view.endPoint = [endPatchView pointForInputPort:endPort];

		[connectionViews addObject:view];
	}	
}

- (WMConnection *)draggingConnectionFromPatchView:(WMPatchView *)inPatchView;
{
	WMDraggingConnection *connection = [draggingConnectionsByPatchKey objectForKey:inPatchView.patch.key];
	return connection;
}

- (void)addDraggingConnectionFromPatchView:(WMPatchView *)inPatch port:(WMPort *)inPort;
{
	WMDraggingConnection *connection = [[WMDraggingConnection alloc] init];
	connection.sourceNode = inPatch.patch.key;
	connection.sourcePort = inPort.key;
	[draggingConnectionsByPatchKey setObject:connection forKey:inPatch.patch.key];
	
	WMConnectionView *view = [[WMConnectionView alloc] initWithFrame:CGRectZero];
	[draggingConnectionViewsByPatchKey setObject:view forKey:inPatch.patch.key];
	[self addSubview:view];
}

- (void)setConnectionEndpoint:(CGPoint)inPoint fromPatchView:(WMPatchView *)inPatch canConnect:(BOOL)inCanConnect;
{
	CGPoint point = [self convertPoint:inPoint fromView:inPatch];
	
	WMDraggingConnection *connection = [draggingConnectionsByPatchKey objectForKey:inPatch.patch.key];
	connection.destinationPoint = point;
	
	WMConnectionView *view = [draggingConnectionViewsByPatchKey objectForKey:inPatch.patch.key];
	view.startPoint = [inPatch pointForOutputPort:[inPatch.patch outputPortWithKey:connection.sourcePort]];
	view.endPoint = point;

	view.alpha = inCanConnect ? 1.0f : 0.5f;
	
}

- (void)removeDraggingConnectionFromPatchView:(WMPatchView *)inPatch;
{
	[draggingConnectionsByPatchKey removeObjectForKey:inPatch.patch.key];
	WMConnectionView *view = [draggingConnectionViewsByPatchKey objectForKey:inPatch.patch.key];
	[view removeFromSuperview];
	[draggingConnectionViewsByPatchKey removeObjectForKey:inPatch.patch.key];
}


@end
