//
//  WMGraphEditView.m
//  WMEdit
//
//  Created by Andrew Pouliot on 7/16/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMGraphEditView.h"

#import "WMPatchConnectionsView.h"
#import "WMPatch.h"
#import "WMPatchView.h"

@implementation WMGraphEditView {
    NSMutableArray *patchViews;
    WMPatchConnectionsView *patchConnectionsView;
}
@synthesize rootPatch;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
	
	patchViews = [[NSMutableArray alloc] init];
	patchConnectionsView = [[WMPatchConnectionsView alloc] initWithFrame:self.bounds];	
	patchConnectionsView.rootPatch = self.rootPatch;
	patchConnectionsView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	patchConnectionsView.graphView = self;
	[self addSubview:patchConnectionsView];
	
	return self;
}

- (void)awakeFromNib;
{
	patchViews = [[NSMutableArray alloc] init];
	patchConnectionsView = [[WMPatchConnectionsView alloc] initWithFrame:self.bounds];
	patchConnectionsView.rootPatch = self.rootPatch;
	patchConnectionsView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	patchConnectionsView.graphView = self;
	[self addSubview:patchConnectionsView];

}


- (void)dealloc
{
	[rootPatch release];
	[patchViews release];
	[patchConnectionsView release];
    [super dealloc];
}

- (void)updateConnectionPositions;
{
	patchConnectionsView.rootPatch = self.rootPatch;
	[patchConnectionsView reloadAllConnections];
}

- (void)addPatch:(WMPatch *)inPatch;
{
	WMPatchView *newNodeView = [[[WMPatchView alloc] initWithPatch:inPatch] autorelease];	
	newNodeView.graphView = self;
	[self addSubview:newNodeView];
	[patchViews addObject:newNodeView];
	
	[inPatch addObserver:self forKeyPath:@"editorPosition" options:NSKeyValueObservingOptionNew context:NULL];
		
	[newNodeView sizeToFit];
	newNodeView.center = inPatch.editorPosition;
	
	[rootPatch addChild:inPatch];
	
	[self updateConnectionPositions];
}

- (void)removePatch:(WMPatch *)inPatch;
{
	[inPatch removeObserver:self forKeyPath:@"editorPosition"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
	if ([keyPath isEqualToString:@"editorPosition"]) {
		[self updateConnectionPositions];
	}
}

- (WMPatchView *)patchViewForKey:(NSString *)inKey;
{
	for (WMPatchView *view in patchViews) {
		if ([view.patch.key isEqualToString:inKey]) {
			return view;
		}
	}
	return nil;
}

#pragma mark - Connection dragging

- (WMPatch *)hitPatchForConnectionWithPoint:(CGPoint)inPoint inPatchView:(WMPatchView *)inView;
{
	for (WMPatchView *patchView in patchViews) {
		WMPort *port = [patchView inputPortAtPoint:inPoint inView:inView];
		if (port) {
			return patchView.patch;
		}
	}
	return nil;
}

- (void)beginDraggingConnectionFromLocation:(CGPoint)inPoint inPatchView:(WMPatchView *)inView;
{
	WMPort *startPort = [inView outputPortAtPoint:inPoint inView:inView];
	NSLog(@"start dragging from port: %@ inView: %@ - %@", startPort, inView, inView.patch);
	if (!startPort) return;
	[patchConnectionsView addDraggingConnectionFromPatchView:inView port:startPort];
}

- (void)continueDraggingConnectionWithLocation:(CGPoint)inPoint inPatchView:(WMPatchView *)inView;
{
	WMPatch *hitPatch = [self hitPatchForConnectionWithPoint:inPoint inPatchView:inView];
	if (hitPatch) {
		WMPort *hitPort = [[self patchViewForKey:hitPatch.key] inputPortAtPoint:inPoint inView:inView];
		
		NSLog(@"touching port: %@", hitPort);
	} else {
		NSLog(@"not touching port");
	}

	[patchConnectionsView setConnectionEndpoint:inPoint fromPatchView:inView];
}

- (void)endDraggingConnectionWithLocation:(CGPoint)inPoint inPatchView:(WMPatchView *)inView;
{
	//Did we connect?
	WMPatch *hitPatch = [self hitPatchForConnectionWithPoint:inPoint inPatchView:inView];
	if (hitPatch) {
		WMPort *hitPort = [[self patchViewForKey:hitPatch.key] inputPortAtPoint:inPoint inView:inView];
		
		if (hitPatch && hitPort) {
			[rootPatch addConnectionFromPort:[(WMPort *)[inView.patch.outputPorts objectAtIndex:0] key] ofPatch:inView.patch.key toPort:hitPort.key ofPatch:hitPatch.key];
		}
	}
	[patchConnectionsView removeDraggingConnectionFromPatchView:inView];
	[patchConnectionsView reloadAllConnections];
}
@end
