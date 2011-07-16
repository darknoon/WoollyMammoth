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

#import "WMDraggingConnection.h"

@implementation WMPatchConnectionsView {
	NSMutableArray *connectionViews;
	
	NSMutableDictionary *draggingConnectionsByPatchKey;
	NSMutableDictionary *draggingConnectionViewsByPatchKey;
}
@synthesize rootPatch;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    connectionViews = [[NSMutableArray alloc] init];
	
	draggingConnectionsByPatchKey = [[NSMutableDictionary alloc] init];
	draggingConnectionViewsByPatchKey = [[NSMutableDictionary alloc] init];
	return self;
}

- (void)dealloc
{
	[draggingConnectionsByPatchKey release];
	[draggingConnectionViewsByPatchKey release];
    [super dealloc];
}


- (void)reloadAllConnections;
{
	for (WMConnectionView *cv in connectionViews) {
		[cv removeFromSuperview];
	}
	[connectionViews removeAllObjects];
	
	for (WMConnection *connection in [rootPatch connections]) {
		WMConnectionView *view = [[[WMConnectionView alloc] initWithFrame:CGRectZero] autorelease];
		
		WMPatch *startPatch = [rootPatch patchWithKey:connection.sourceNode];
		WMPatch *endPatch = [rootPatch patchWithKey:connection.destinationNode];
			
		[self addSubview:view];
		view.startPoint = startPatch.editorPosition;
		view.endPoint = endPatch.editorPosition;

		[connectionViews addObject:view];
	}	
}

- (void)addDraggingConnectionFromPatchView:(WMPatchView *)inPatch;
{
	WMDraggingConnection *connection = [[[WMDraggingConnection alloc] init] autorelease];
	[draggingConnectionsByPatchKey setObject:connection forKey:inPatch.patch.key];
	
	WMConnectionView *view = [[[WMConnectionView alloc] initWithFrame:CGRectZero] autorelease];
	[draggingConnectionViewsByPatchKey setObject:view forKey:inPatch.patch.key];
	[self addSubview:view];
}

- (void)setConnectionEndpoint:(CGPoint)inPoint fromPatchView:(WMPatchView *)inPatch;
{
	CGPoint point = [self convertPoint:inPoint fromView:inPatch];
	
	WMDraggingConnection *connection = [draggingConnectionsByPatchKey objectForKey:inPatch];
	connection.destinationPoint = point;
	
	WMConnectionView *view = [draggingConnectionViewsByPatchKey objectForKey:inPatch.patch.key];
	view.endPoint = point;
	view.startPoint = inPatch.patch.editorPosition;
}

- (void)removeDraggingConnectionFromPatchView:(WMPatchView *)inPatch;
{
	[draggingConnectionsByPatchKey removeObjectForKey:inPatch.patch.key];
	WMConnectionView *view = [draggingConnectionViewsByPatchKey objectForKey:inPatch.patch.key];
	[view removeFromSuperview];
	[draggingConnectionViewsByPatchKey removeObjectForKey:inPatch.patch.key];
}


@end
