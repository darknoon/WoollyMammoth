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
#import "NSObject_KVOBlockNotificationExtensions.h"

#import <WMGraph/WMGraph.h>

@implementation WMGraphEditView {
    NSMutableArray *patchViews;
    WMPatchConnectionsView *patchConnectionsView;
	WMConnectionPopover *connectionPopover;
	
	CGPoint editorScrollPosition;
	
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
	
	CGSize contentSize = (CGSize){.width = 20000, .height = 20000};
	self.contentSize = contentSize;
	editorScrollPosition = (CGPoint){.x = contentSize.width/2, .y = contentSize.width/2};
	self.delaysContentTouches = NO;
	
	self.delegate = (id <UIScrollViewDelegate>)self;

	self.minimumZoomScale = 0.3f;
	self.maximumZoomScale = 1.0f;
	self.decelerationRate = UIScrollViewDecelerationRateFast;

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

- (void)dealloc;
{
	//Un-observe patches
	for (WMPatch *patch in rootPatch.children) {
		[patch removeObserver:self forKeyPath:KVC(patch, editorPosition) identifier:nil];
		[patch removeObserver:self forKeyPath:KVC(patch, inputPorts) identifier:nil];
		[patch removeObserver:self forKeyPath:KVC(patch, outputPorts) identifier:nil];
	}
}

- (void)didMoveToWindow;
{
	CGRect frame = self.frame;
	self.contentOffset = (CGPoint){.x = editorScrollPosition.x - frame.size.width / 2, .y = editorScrollPosition.y - frame.size.height / 2};
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
		
	__weak WMGraphEditView *weakSelf = self;
	[inPatch addObserver:self handler:^(NSString *keyPath, id object, NSDictionary *change, id identifier) {
		[weakSelf updateConnectionPositions];
	} forKeyPath:KVC(inPatch, editorPosition) options:0 identifier:nil];
	
	__weak WMPatchView *weakNodeView = newNodeView;
	KVOBlock portsChanged = ^(NSString *keyPath, id object, NSDictionary *change, id identifier) {
		[weakNodeView setNeedsLayout];
		[weakSelf updateConnectionPositions];
	};
	
	[inPatch addObserver:self handler:portsChanged forKeyPath:KVC(inPatch, inputPorts) options:0 identifier:nil];
	[inPatch addObserver:self handler:portsChanged forKeyPath:KVC(inPatch, outputPorts) options:0 identifier:nil];
	
	//Make sure setup gets called before we decide on the node size
	[viewController modifyNodeGraphWithBlock:^(WMPatch *p) {
		[p addChild:inPatch];
	}];

	newNodeView.center = [self pointForEditorPosition:inPatch.editorPosition];
	[newNodeView sizeToFit];
	newNodeView.frame = CGRectIntegral(newNodeView.frame);
	//This is required so that we know the position of the connections so we can draw the connections properly
	[newNodeView layoutIfNeeded];

	[self updateConnectionPositions];
}

- (void)removePatch:(WMPatch *)inPatch;
{
	WMPatchView *patchView = [self patchViewForKey:inPatch.key];

	[inPatch removeObserver:self forKeyPath:KVC(inPatch, editorPosition) identifier:nil];
	[inPatch removeObserver:self forKeyPath:KVC(inPatch, inputPorts) identifier:nil];
	[inPatch removeObserver:self forKeyPath:KVC(inPatch, outputPorts) identifier:nil];
	[viewController modifyNodeGraphWithBlock:^(WMPatch *p) {
		[p removeChild:inPatch];
	}];
	
	[patchViews removeObject:patchView];
	[patchView removeFromSuperview];
	[self updateConnectionPositions];
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

#pragma mark - 


- (CGPoint)editorPositionForPoint:(CGPoint)inPoint;
{
	return (CGPoint){inPoint.x - (self.contentSize.width / 2), inPoint.y - (self.contentSize.height / 2)};
}

- (CGPoint)pointForEditorPosition:(CGPoint)inEditorPosition;
{
	return (CGPoint){inEditorPosition.x + (self.contentSize.width / 2), inEditorPosition.y + (self.contentSize.height / 2)};
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
	if (hitPatch != nil) {
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
		[connectionPopover.superview bringSubviewToFront:connectionPopover];
		
		// DLog(@"%@ touching port: %@", canConnect ? @"Y" : @"N", hitPort);
	} else {
		//Are we still in the output ports?
		//Allow switching which output port we're selecting by dragging
		WMPort *sourcePort = [inView outputPortAtPoint:inPoint inView:inView];
		if (sourcePort) {
			connectionPopover.hidden = NO;
			connectionPopover.ports = inView.patch.outputPorts;
			connectionPopover.connectablePorts = [[NSSet alloc] initWithArray:inView.patch.outputPorts];
			connectionPopover.connectionIndex = [inView.patch.outputPorts indexOfObject:sourcePort];
			[connectionPopover setTargetPoint: [inView pointForOutputPort:sourcePort]];
			connectionPopover.canConnect = canConnect;
			[connectionPopover refresh];
			[connectionPopover.superview bringSubviewToFront:connectionPopover];

			WMConnection *connection = [patchConnectionsView draggingConnectionFromPatchView:inView];
			connection.sourcePort = sourcePort.name;
		} else {
			connectionPopover.hidden = YES;
		}
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
			[viewController modifyNodeGraphWithBlock:^(WMPatch *graph) {
				[graph addConnectionFromPort:sourcePort.key ofPatch:inView.patch.key toPort:hitPort.key ofPatch:hitPatch.key];
			}];
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
