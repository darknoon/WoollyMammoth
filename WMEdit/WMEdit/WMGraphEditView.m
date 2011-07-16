//
//  WMGraphEditView.m
//  WMEdit
//
//  Created by Andrew Pouliot on 7/16/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMGraphEditView.h"

#import "WMPatchConnectionsView.h"
#import "WMPatchView.h"

@implementation WMGraphEditView {
    NSMutableArray *patchViews;
    WMPatchConnectionsView *patchConnectionsView;
}
@synthesize rootPatch;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

	patchConnectionsView = [[WMPatchConnectionsView alloc] initWithFrame:self.bounds];	
	patchConnectionsView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self addSubview:patchConnectionsView];
	
	return self;
}

- (void)awakeFromNib;
{
	patchConnectionsView = [[WMPatchConnectionsView alloc] initWithFrame:self.bounds];
	patchConnectionsView.rootPatch = self.rootPatch;
	patchConnectionsView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self addSubview:patchConnectionsView];

}

- (void)updateConnectionPositions;
{
	patchConnectionsView.rootPatch = self.rootPatch;
	[patchConnectionsView reloadAllConnections];
}

- (void)addPatch:(WMPatch *)inPatch;
{
	WMPatchView *newNodeView = [[[WMPatchView alloc] initWithPatch:inPatch] autorelease];	
	[self addSubview:newNodeView];
	
	[inPatch addObserver:self forKeyPath:@"editorPosition" options:NSKeyValueObservingOptionNew context:NULL];
	
	[newNodeView sizeToFit];
	newNodeView.center = inPatch.editorPosition;
	
	[rootPatch addChild:inPatch];

	if (rootPatch.children.count == 2) {
		//Add a connection from 
		[rootPatch addConnectionFromPort:@"blah" ofPatch:@"node-1" toPort:@"_enable" ofPatch:@"node-2"];
	}
	
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

- (void)dealloc
{
    [super dealloc];
}

@end
