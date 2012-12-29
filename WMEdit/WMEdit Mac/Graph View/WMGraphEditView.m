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
	
	NSView *_addNodePlaceholderView;
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
	if (!_nodeCreationPopover) {
		
		WMAddNodeViewController *addNodeViewController = [[WMAddNodeViewController alloc] initWithNibName:nil bundle:nil];
		addNodeViewController.delegate = self;
		
		NSPopover *popover = [[NSPopover alloc] init];
		popover.behavior = NSPopoverBehaviorTransient;
		popover.contentViewController = addNodeViewController;
		popover.delegate = self;
		popover.appearance = NSPopoverAppearanceHUD;
		
		NSPoint p = theEvent.locationInWindow;
		p = [self convertPoint:p fromView:nil];
		[popover showRelativeToRect:(NSRect){p.x, p.y, 1, 1} ofView:self preferredEdge:CGRectMinYEdge];
		_nodeCreationPopover = popover;
		
		if (!_addNodePlaceholderView) {
			_addNodePlaceholderView = [[NSView alloc] initWithFrame:NSZeroRect];
			_addNodePlaceholderView.wantsLayer = YES;
			_addNodePlaceholderView.layer.contents = [NSImage imageNamed:@"AddNodeHighlight"];
			_addNodePlaceholderView.layer.contentsGravity = kCAGravityCenter;
		}
		_addNodePlaceholderView.frame = (NSRect){p, 0, 0};
		_addNodePlaceholderView.layer.opacity = 1.0;
		CABasicAnimation *fadeIn = [CABasicAnimation animationWithKeyPath:@"opacity"];
		fadeIn.fromValue = @(0.0);
		fadeIn.toValue = @(1.0);
		fadeIn.additive = YES;
		[_addNodePlaceholderView.layer addAnimation:fadeIn forKey:fadeIn.keyPath];
		[self addSubview:_addNodePlaceholderView];
		
		CAKeyframeAnimation *pulseAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
		pulseAnimation.values = @[@(1.0), @(0.3), @(1.0)];
		pulseAnimation.duration = 4.0;
		pulseAnimation.timeOffset = 1.0;
		pulseAnimation.repeatCount = HUGE_VALF;
		[_addNodePlaceholderView.layer addAnimation:pulseAnimation forKey:@"pulse"];
		pulseAnimation.additive = YES;
	} else {
		[super mouseDown:theEvent];
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
	CABasicAnimation *fadeOut = [CABasicAnimation animationWithKeyPath:@"opacity"];
	fadeOut.fromValue = @(((CALayer *)_addNodePlaceholderView.layer.presentationLayer).opacity);
	fadeOut.toValue = @(0.0);
	fadeOut.additive = YES;
	[_addNodePlaceholderView.layer addAnimation:fadeOut forKey:fadeOut.keyPath];
	_addNodePlaceholderView.layer.opacity = 0.0;
	[_addNodePlaceholderView.layer removeAnimationForKey:@"pulse"];
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
