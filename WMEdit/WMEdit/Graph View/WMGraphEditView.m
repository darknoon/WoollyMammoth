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
#import "WMConnectionPopover.h"
#import "WMCustomPopover.h"
#import "WMEditViewController.h"

#import "WMPatch.h"
#import "WMConnection.h"

@implementation WMGraphEditView {
    NSMutableArray *patchViews;
    WMPatchConnectionsView *patchConnectionsView;
	WMConnectionPopover *connectionPopover;
	
	UIView *contentView;
	
	UIImageView *lighting;
}
@synthesize rootPatch;
@synthesize viewController;

- (void)initShared;
{
	lighting = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"connection-lighting"]];
	[self addSubview:lighting];
	lighting.center = (CGPoint){CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds)};
	lighting.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
	lighting.alpha = 0.0f;
	
	self.contentSize = (CGSize){.width = 2000, .height = 2000};
	self.contentOffset = (CGPoint){.x = 500, .y = 500};
	self.delaysContentTouches = NO;
	
	self.delegate = (id <UIScrollViewDelegate>)self;

	self.minimumZoomScale = 0.1f;
	self.maximumZoomScale = 1.0f;

	contentView = [[UIView alloc] initWithFrame:(CGRect){.size = self.contentSize}];
	//TODO: why doesn't this work?
	contentView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"background-tile"]];
	[self addSubview:contentView];
	
	patchViews = [[NSMutableArray alloc] init];
	patchConnectionsView = [[WMPatchConnectionsView alloc] initWithFrame:(CGRect){.size = self.contentSize}];	
	patchConnectionsView.rootPatch = self.rootPatch;
	patchConnectionsView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	patchConnectionsView.graphView = self;
	[contentView addSubview:patchConnectionsView];
	
	connectionPopover = [[WMConnectionPopover alloc] initWithFrame:CGRectZero];
	connectionPopover.hidden = YES;
	[contentView addSubview:connectionPopover];

}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
	
	[self initShared];
	
	return self;
}

- (void)awakeFromNib;
{
	[self initShared];
}



- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch;
{
	if (gestureRecognizer == self.panGestureRecognizer) {
		return ![self patchHit:[touch locationInView:self]];
	} else if (gestureRecognizer == self.pinchGestureRecognizer) {
		NSLog(@"Zoom scale: %f", self.zoomScale);
		return YES;
	} else {
		return YES;
	}
}

- (BOOL)patchHit:(CGPoint)pt {
//    pt = [self convertPoint:pt fromView:[self superview]];
    for (WMPatchView *p in patchViews) {
        CGRect r = [p frame];
        if (CGRectContainsPoint(r, pt)) return YES;
    }
    return NO;
}
- (void)updateConnectionPositions;
{
	patchConnectionsView.rootPatch = self.rootPatch;
	[patchConnectionsView reloadAllConnections];
}

- (void)addPatch:(WMPatch *)inPatch;
{
	WMPatchView *newNodeView = [[WMPatchView alloc] initWithPatch:inPatch];	
	newNodeView.graphView = self;
	[contentView addSubview:newNodeView];
	[patchViews addObject:newNodeView];
	
	[inPatch addObserver:self forKeyPath:@"editorPosition" options:NSKeyValueObservingOptionNew context:NULL];
	
	//Make sure setup gets called before we decide on the node size
	[rootPatch addChild:inPatch];

	newNodeView.center = inPatch.editorPosition;
	[newNodeView sizeToFit];
	newNodeView.frame = CGRectIntegral(newNodeView.frame);

	[self updateConnectionPositions];
}

- (void)removePatch:(WMPatch *)inPatch;
{
	WMPatchView *patchView = [self patchViewForKey:inPatch.key];

	[inPatch removeObserver:self forKeyPath:@"editorPosition"];
	[rootPatch removeChild:inPatch];
	
	[patchViews removeObject:patchView];
	[patchView removeFromSuperview];
	[self updateConnectionPositions];
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
	
	[UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
		lighting.alpha = 1.0f;
	} completion: NULL];;
}

- (void)continueDraggingConnectionWithLocation:(CGPoint)inPoint inPatchView:(WMPatchView *)inView;
{
	WMPatch *hitPatch = [self hitPatchForConnectionWithPoint:inPoint inPatchView:inView];
	BOOL canConnect = NO;
	if (hitPatch) {
		WMPatchView *hitPatchView = [self patchViewForKey:hitPatch.key];
		WMPort *hitPort = [hitPatchView inputPortAtPoint:inPoint inView:inView];
		
		WMConnection *connection = [patchConnectionsView draggingConnectionFromPatchView:inView];
		
		WMPort *sourcePort = [inView.patch outputPortWithKey:connection.sourcePort];
		
		canConnect = [hitPort canTakeValueFromPort:sourcePort];
		
		NSMutableSet *connectablePorts = [NSMutableSet set];
		for (WMPort *p in hitPatchView.patch.inputPorts) {
			if ([p canTakeValueFromPort:sourcePort]) {
				[connectablePorts addObject:p];
			}
		}
		
		//Show connection popover
		connectionPopover.hidden = NO;
		connectionPopover.ports = hitPatch.inputPorts;
		connectionPopover.connectablePorts = connectablePorts;
		connectionPopover.connectionIndex = [hitPatch.inputPorts indexOfObject:hitPort];
		[connectionPopover setTargetPoint: [hitPatchView pointForInputPort:hitPort]];
		connectionPopover.canConnect = canConnect;
		[connectionPopover refresh];
		[self bringSubviewToFront:connectionPopover];
		
		// DLog(@"%@ touching port: %@", canConnect ? @"Y" : @"N", hitPort);
	} else {
		connectionPopover.hidden = YES;
		// DLog(@"not touching port");
	}

	[patchConnectionsView setConnectionEndpoint:inPoint fromPatchView:inView canConnect:canConnect];
}

- (void)endDraggingConnectionWithLocation:(CGPoint)inPoint inPatchView:(WMPatchView *)inView;
{
	//Did we connect?
	WMPatch *hitPatch = [self hitPatchForConnectionWithPoint:inPoint inPatchView:inView];
	if (hitPatch) {
		WMPort *hitPort = [[self patchViewForKey:hitPatch.key] inputPortAtPoint:inPoint inView:inView];
		WMConnection *connection = [patchConnectionsView draggingConnectionFromPatchView:inView];
		WMPort *sourcePort = [inView.patch outputPortWithKey:connection.sourcePort];

		BOOL canConnect = [hitPort canTakeValueFromPort:sourcePort];
		if (hitPatch && hitPort && canConnect) {
			[rootPatch addConnectionFromPort:sourcePort.key ofPatch:inView.patch.key toPort:hitPort.key ofPatch:hitPatch.key];
		}
	}
	[patchConnectionsView removeDraggingConnectionFromPatchView:inView];
	[patchConnectionsView reloadAllConnections];
	
	[UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
		lighting.alpha = 0.0f;
	} completion: NULL];
	
	connectionPopover.hidden = YES;
}

- (void)inputPortStripTappedWithRect:(CGRect)inInputPortsRect patchView:(WMPatchView *)inPatchView;
{
	[self.viewController inputPortStripTappedWithRect:inInputPortsRect patchView:inPatchView];
}

- (void)showSettingsForPatchView:(WMPatchView *)inPatchView;
{
	[self.viewController showSettingsForPatchView:inPatchView];
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView;
{
	return contentView;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale;
{
	
}

@end
