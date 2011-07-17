//
//  WMPatchView.m
//  WMEdit
//
//  Created by Andrew Pouliot on 7/15/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMPatchView.h"
#import "WMPatchPlugStripView.h"
#import "CGRoundRect.h"
#import "WMPatch.h"
#import "WMGraphEditView.h"

@implementation WMPatchView {
	WMPatchPlugStripView *inputPlugStrip;
	WMPatchPlugStripView *outputPlugStrip;
	WMPatch *patch;
	
	UILabel *label;
}

@synthesize dragging;
@synthesize draggable;
@synthesize graphView;

- (id)initWithPatch:(WMPatch *)inPatch;
{
	self = [self initWithFrame:CGRectZero];
	if (!self) return nil;
	
	self.opaque = NO;
	self.draggable = YES;
	
	patch = [inPatch retain];
	
	inputPlugStrip = [[WMPatchPlugStripView alloc] initWithFrame:CGRectZero];
	inputPlugStrip.inputCount = 3;
	[self addSubview:inputPlugStrip];
	
	outputPlugStrip = [[WMPatchPlugStripView alloc] initWithFrame:CGRectZero];
	outputPlugStrip.inputCount = 2;
	[self addSubview:outputPlugStrip];
	
	UIGestureRecognizer *inputRecognizer = [[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(inputPlugsPan:)] autorelease];
	[inputPlugStrip addGestureRecognizer:inputRecognizer];

	UIGestureRecognizer *outputRecognizer = [[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(outputPlugsPan:)] autorelease];
	[outputPlugStrip addGestureRecognizer:outputRecognizer];
	
	UITapGestureRecognizer *tapRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)] autorelease];
	[self addGestureRecognizer:tapRecognizer];

	label = [[UILabel alloc] initWithFrame:CGRectZero];
	label.text = [[inPatch class] humanReadableTitle];
    label.minimumFontSize = 10.0f;
	label.shadowColor = [UIColor blackColor];
	label.shadowOffset = (CGSize){.height = -1};
	label.textColor = [UIColor whiteColor];
	label.backgroundColor = [UIColor clearColor];
	label.font = [UIFont boldSystemFontOfSize:14.f];
    label.textAlignment = UITextAlignmentCenter;
	[self addSubview:label];
	
    return self;
}

- (void)dealloc
{
	[label release];
	[patch release];
    [super dealloc];
}

- (WMPatch *)patch;
{
	return [[patch retain] autorelease];
}

- (void)layoutSubviews;
{
	inputPlugStrip.inputCount = patch.inputPorts.count;
	inputPlugStrip.frame = (CGRect){.origin.x = 20.f, .origin.y = 0};
	[inputPlugStrip sizeToFit];

	outputPlugStrip.inputCount = patch.outputPorts.count;
	outputPlugStrip.frame = (CGRect){.origin.x = 20.f, .origin.y = self.bounds.size.height - 20.f};
	[outputPlugStrip sizeToFit];
	
	CGRect labelFrame = UIEdgeInsetsInsetRect(self.bounds, (UIEdgeInsets){.top = 28.f, .bottom = 28.f});
	label.frame = labelFrame;
}

- (CGSize)sizeThatFits:(CGSize)size;
{
	size.width = [inputPlugStrip sizeThatFits:CGSizeZero].width + 40.f;
	size.height = 68.f;
	return size;
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef ctx = UIGraphicsGetCurrentContext();

	[[UIColor colorWithWhite:0.0f alpha:0.5f] setFill];
	CGContextAddRoundRect(ctx, self.bounds, 9.0f);
	CGContextFillPath(ctx);

	CGContextAddRoundRect(ctx, CGRectInset(self.bounds, 0.5f, 0.5f), 9.0f);
	CGContextStrokePath(ctx);
	
}

- (void)inputPlugsPan:(UIPanGestureRecognizer *)inR;
{
	NSLog(@"inputPlugsPan: %d", inR.state);
	
}

- (void)outputPlugsPan:(UIPanGestureRecognizer *)inR;
{
	if (inR.state == UIGestureRecognizerStateBegan) {
		[graphView beginDraggingConnectionFromLocation:[inR locationInView:self] inPatchView:self];
	} else if (inR.state == UIGestureRecognizerStateChanged) {
		[graphView continueDraggingConnectionWithLocation:[inR locationInView:self] inPatchView:self];
	} else if (inR.state == UIGestureRecognizerStateEnded) {
		[graphView endDraggingConnectionWithLocation:[inR locationInView:self] inPatchView:self];
	}
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	if (draggable) {
		dragging = YES;
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	if (draggable && dragging) {
		UITouch *touch = [touches anyObject];
		CGPoint location = [touch locationInView:self];
		CGPoint previous = [touch previousLocationInView:self];
		CGPoint center = self.center;
		center.x += location.x - previous.x;
		center.y += location.y - previous.y;
		
		self.center = center;
		self.patch.editorPosition = center;
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if (draggable && dragging) {
		CGPoint center = self.center;
		self.center = center;
		dragging = NO;
	}
}


#pragma mark -

- (WMPort *)inputPortAtPoint:(CGPoint)inPoint inView:(UIView *)inView;
{
	BOOL inInputs = [inputPlugStrip pointInside:[inputPlugStrip convertPoint:inPoint fromView:inView] withEvent:nil];
	
	if (inInputs && patch.inputPorts.count > 0) {
		return [patch.inputPorts objectAtIndex:0];
		
		CGFloat offX = (inPoint.x - leftOffset) / offsetBetweenDots;
		int offXi = (int)roundf(offX);
		offXi = MAX(0, MIN(offXi, patch.inputPorts.count));
		
		return [patch.inputPorts objectAtIndex:offXi];
	}
	return nil;
}


- (WMPort *)outputPortAtPoint:(CGPoint)inPoint inView:(UIView *)inView;
{
	BOOL inOutputs = [outputPlugStrip pointInside:[outputPlugStrip convertPoint:inPoint fromView:inView] withEvent:nil];

	if (inOutputs && patch.outputPorts.count > 0) {
		CGFloat offX = (inPoint.x - leftOffset) / offsetBetweenDots;
		int offXi = (int)roundf(offX);
		offXi = MAX((int)0, (int)MIN((int)offXi, patch.outputPorts.count - 1));

		return [patch.outputPorts objectAtIndex:offXi];
	}
	
	return nil;
	
}

- (CGPoint)pointForInputPort:(WMPort *)inputPort;
{
	WMPort *port = [self.patch inputPortWithKey:inputPort.key];
	if (port) {
		NSUInteger idx = [patch.inputPorts indexOfObject:port];
		if (idx != NSNotFound) {
			CGPoint p = (CGPoint){.x = leftOffset + idx * offsetBetweenDots, .y = inputPlugStrip.frame.origin.y + plugstripHeight / 2.f};
			return [self convertPoint:p toView:self.superview];
		}
	}
	return patch.editorPosition;

}

- (CGPoint)pointForOutputPort:(WMPort *)outputPort;
{
	WMPort *port = [self.patch outputPortWithKey:outputPort.key];
	if (port) {
		NSUInteger idx = [patch.outputPorts indexOfObject:port];
		if (idx != NSNotFound) {
			CGPoint p = (CGPoint){.x = leftOffset + idx * offsetBetweenDots, .y = outputPlugStrip.frame.origin.y + plugstripHeight / 2.f};
			return [self convertPoint:p toView:self.superview];
		}
	}
	return patch.editorPosition;
}

#pragma mark - Menu


- (BOOL)canBecomeFirstResponder;
{
	return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
	return action == @selector(delete:);
}

- (void)tapped:(UITapGestureRecognizer *)inR;
{
	[[UIMenuController sharedMenuController] setTargetRect:self.bounds inView:self];
	[[UIMenuController sharedMenuController] setMenuVisible:YES animated:YES];
	
	[self becomeFirstResponder];
	
}

- (void)delete:(id)sender;
{
	[graphView removePatch:self.patch];
}

@end
