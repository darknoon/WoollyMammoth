//
//  WMGraphEditView.m
//  WMEdit
//
//  Created by Andrew Pouliot on 12/26/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import "WMGraphEditView.h"
#import "WMAddNodeViewController.h"

@interface WMGraphEditView () <WMAddNodeViewControllerDelegate, NSPopoverDelegate>

@end

@implementation WMGraphEditView {
	NSPopover *_nodeCreationPopover;
}

- (void)awakeFromNib;
{
	[super awakeFromNib];
	
	self.superview.wantsLayer = YES;

	CALayer *backgroundLayer = [[CALayer alloc] init];
	backgroundLayer.frame = CGRectInset(self.bounds, -100, -100);
	
	[self.layer addSublayer:backgroundLayer];
	
	backgroundLayer.backgroundColor = [NSColor colorWithPatternImage:[NSImage imageNamed:@"EditorBackgroundPattern"]].CGColor;
//	self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawOnSetNeedsDisplay;
}

- (void)mouseDown:(NSEvent *)theEvent;
{
	NSLog(@"Mousedown: %@", theEvent);
	if (!_nodeCreationPopover) {
		WMAddNodeViewController *addNodeViewController = [[WMAddNodeViewController alloc] initWithNibName:nil bundle:nil];
		addNodeViewController.delegate = self;
		
		NSPopover *popover = [[NSPopover alloc] init];
		popover.behavior = NSPopoverBehaviorTransient;
		popover.contentViewController = addNodeViewController;
		popover.delegate = self;
		popover.appearance = NSPopoverAppearanceHUD;
		
		[popover showRelativeToRect:(NSRect){theEvent.locationInWindow.x, theEvent.locationInWindow.y, 1, 1} ofView:self preferredEdge:CGRectMinYEdge];
		_nodeCreationPopover = popover;
	}
}

#pragma mark - NSPopoverDelegate

- (BOOL)popoverShouldClose:(NSPopover *)popover;
{
	return YES;
}

- (void)popoverWillClose:(NSNotification *)notification;
{
	[[((WMAddNodeViewController *)_nodeCreationPopover.contentViewController) searchField] resignFirstResponder];
}

- (void)popoverDidClose:(NSNotification *)notification;
{
	_nodeCreationPopover = nil;
}

#pragma mark - WMAddNodeViewControllerDelegate

- (void)addNodeViewController:(WMAddNodeViewController *)controller finishWithNodeNamed:(NSString *)nodeText;
{
	//TODO: add a node!
	[_nodeCreationPopover performClose:nil];
	_nodeCreationPopover = nil;
}

- (void)addNodeCancel:(WMAddNodeViewController *)controller;
{
	[_nodeCreationPopover performClose:nil];
	_nodeCreationPopover = nil;
}

@end
