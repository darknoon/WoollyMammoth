//
//  WMPatchConnectionsView.m
//  WMEdit
//
//  Created by Andrew Pouliot on 7/16/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMPatchConnectionsView.h"

#import "WMConnection.h"
#import "WMConnectionView.h"

@implementation WMPatchConnectionsView {
	NSMutableArray *connectionViews;
}
@synthesize rootPatch;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    connectionViews = [[NSMutableArray alloc] init];
	
//	WMConnectionView *cvtest = [[[WMConnectionView alloc] initWithFrame:CGRectZero] autorelease];
//	cvtest.startPoint = (CGPoint){100,300};
//	cvtest.endPoint = (CGPoint){520,640};
//	[self addSubview:cvtest];
	
	return self;
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

- (void)dealloc
{
    [super dealloc];
}

@end
