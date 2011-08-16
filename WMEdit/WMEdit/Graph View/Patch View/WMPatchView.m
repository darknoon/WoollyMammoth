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
#import "WMPatch+SettingsControllerClass.h"

static const CGFloat bodyRadius = 9.f;
static const CGFloat bodyHeight = 45.f;
static const CGFloat plugStripRadius = 11.f;
static const UIEdgeInsets insets = {.top = 11.f, .left = 10.f, .right = 10.f, .bottom = 11.f};

@implementation WMPatchView {
	WMPatchPlugStripView *inputPlugStrip;
	WMPatchPlugStripView *outputPlugStrip;
	WMPatch *patch;
	
	BOOL draggingOutputConnection;
	
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
	
	patch = inPatch;
	
	inputPlugStrip = [[WMPatchPlugStripView alloc] initWithFrame:CGRectZero];
	inputPlugStrip.inputCount = 3;
	[self addSubview:inputPlugStrip];
	
	outputPlugStrip = [[WMPatchPlugStripView alloc] initWithFrame:CGRectZero];
	outputPlugStrip.inputCount = 2;
	[self addSubview:outputPlugStrip];
		
	UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
	[self addGestureRecognizer:tapRecognizer];
	
	UIGestureRecognizer *inputTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(inputsTapped:)];
	[inputPlugStrip addGestureRecognizer:inputTapRecognizer];

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
	
	self.contentMode = UIViewContentModeRedraw;
	
	inputPlugStrip.inputCount = patch.inputPorts.count;
	outputPlugStrip.inputCount = patch.outputPorts.count;
	[self sizeToFit];
	[self setNeedsDisplay];
	
    return self;
}


- (WMPatch *)patch;
{
	return patch;
}

- (void)layoutSubviews;
{
	const CGSize topPlugsSize = [inputPlugStrip sizeThatFits:CGSizeZero];
	const CGSize bottomPlugsSize = [outputPlugStrip sizeThatFits:CGSizeZero];
	
	CGRect bounds = self.bounds;

	inputPlugStrip.inputCount = patch.inputPorts.count;
	inputPlugStrip.frame = (CGRect){.origin.x = CGRectGetMidX(bounds) - topPlugsSize.width/2, .origin.y = 0, .size = topPlugsSize};
	[inputPlugStrip sizeToFit];

	outputPlugStrip.inputCount = patch.outputPorts.count;
	outputPlugStrip.frame = (CGRect){.origin.x = CGRectGetMidX(bounds) - bottomPlugsSize.width/2, .origin.y = self.bounds.size.height - plugstripHeight, .size = bottomPlugsSize};
	[outputPlugStrip sizeToFit];
	
	CGRect labelFrame = UIEdgeInsetsInsetRect(self.bounds, (UIEdgeInsets){.top = 28.f, .bottom = 28.f});
	label.frame = labelFrame;
}

- (CGSize)sizeThatFits:(CGSize)size;
{
	const CGFloat topPlugsWidth = [inputPlugStrip sizeThatFits:CGSizeZero].width;
	const CGFloat bottomPlugsWidth = [outputPlugStrip sizeThatFits:CGSizeZero].width;
	const CGFloat textWidth = [label sizeThatFits:CGSizeZero].width;

	size.width = MAX(MAX(topPlugsWidth, bottomPlugsWidth) + bodyRadius * 2.f, textWidth) + insets.left + insets.right + plugStripRadius * 2;
	size.height = bodyHeight + plugStripRadius * 2 + insets.top + insets.bottom;
	return size;
}

- (UIBezierPath *)pathForPatchBodyInRect:(CGRect)insetRect withTopPlugsWidth:(CGFloat)topPlugsWidth bottomPlugsWidth:(CGFloat)bottomPlugsWidth;
{
	/*
	 * 
	 *   y0_  __          __
	 *   y1_ /  \________/  \
	 *       |              |
	 *   y2_ |     ___      |
	 *   y3_ \____/   \_____/
	 *     xb0    xb3 xb4    xb7
	 *       xb1 xb2   xb5 xb6
	 */
	
	const CGFloat y0 = CGRectGetMinY(insetRect);
	const CGFloat y1 = y0 + plugStripRadius;
	
	const CGFloat y3 = CGRectGetMaxY(insetRect);
	const CGFloat y2 = y3 - plugStripRadius;
	
	const CGFloat xt0 = CGRectGetMinX(insetRect);
	const CGFloat xt1 = xt0 + bodyRadius;
	const CGFloat xt2 = CGRectGetMidX(insetRect) - topPlugsWidth/2;
	const CGFloat xt3 = xt2 + plugStripRadius;
	
	const CGFloat xt7 = CGRectGetMaxX(insetRect);
	const CGFloat xt6 = xt7 - bodyRadius;
	const CGFloat xt5 = CGRectGetMidX(insetRect) + topPlugsWidth/2;
	const CGFloat xt4 = xt5 - plugStripRadius;
	
	const CGFloat xb0 = CGRectGetMinX(insetRect);
	const CGFloat xb1 = xt0 + bodyRadius;
	const CGFloat xb2 = CGRectGetMidX(insetRect) - bottomPlugsWidth/2;
	const CGFloat xb3 = xt2 + plugStripRadius;
	
	const CGFloat xb7 = CGRectGetMaxX(insetRect);
	const CGFloat xb6 = xt7 - bodyRadius;
	const CGFloat xb5 = CGRectGetMidX(insetRect) + bottomPlugsWidth/2;
	const CGFloat xb4 = xt5 - plugStripRadius;
	
	
	CGMutablePathRef path = CGPathCreateMutable();
	const CGAffineTransform *t = NULL;
	
	CGPathMoveToPoint(path, t, xt0, y1);
	CGPathAddArcToPoint(path, t, xt0,y0, xt1,y0, bodyRadius);
	CGPathAddLineToPoint(path, t, xt2, y0);
	
	//Arc down to baseline
	CGPathAddArcToPoint(path, t, xt2,y1, xt3,y1, plugStripRadius);
	//Go across bottom of plug strip
	CGPathAddLineToPoint(path, t, xt4, y1);
	//Arc up to top
	CGPathAddArcToPoint(path, t, xt5,y1, xt5,y0, plugStripRadius);
	
	//Move to right
	CGPathAddLineToPoint(path, t, xt6, y0);
	//Arc down
	CGPathAddArcToPoint(path, t, xt7, y0, xt7, y1, bodyRadius);
	
	//Line down
	CGPathAddLineToPoint(path, t, xb7, y2);
	//Arc over
	CGPathAddArcToPoint(path, t, xb7,y3, xb6,y3, bodyRadius);
	//Line across
	CGPathAddLineToPoint(path, t, xb5, y3);
	//Arc up
	CGPathAddArcToPoint(path, t, xb5,y2, xb4,y2, plugStripRadius);
	
	//line across top of plug strip
	CGPathAddLineToPoint(path, t, xb3, y2);
	//Arc to bottom
	CGPathAddArcToPoint(path, t, xb2,y2, xb2, y3, plugStripRadius);
	//line over
	CGPathAddLineToPoint(path, t, xb1,y3);
	//Arc up
	CGPathAddArcToPoint(path, t, xb0,y3, xb0,y2, bodyRadius);
	
	CGPathCloseSubpath(path);
	
	UIBezierPath *p = [UIBezierPath bezierPathWithCGPath:path];
	
	CGPathRelease(path);

	return p;
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	
	[self.patch.editorColor setFill];
	
	CGContextSaveGState(ctx);
	
	CGRect bounds = self.bounds;	
	const CGRect insetRect = UIEdgeInsetsInsetRect(bounds, insets);
	
	NSLog(@"drawing in bounds: %@", NSStringFromCGRect(bounds));
	
	const CGFloat topPlugsWidth = [inputPlugStrip sizeThatFits:CGSizeZero].width;
	const CGFloat bottomPlugsWidth = [outputPlugStrip sizeThatFits:CGSizeZero].width;

	UIBezierPath *p = [self pathForPatchBodyInRect:insetRect withTopPlugsWidth:topPlugsWidth bottomPlugsWidth:bottomPlugsWidth];
	
	CGContextSetShadowWithColor(ctx, (CGSize){.height = 2.f}, 3.f, [[UIColor blackColor] CGColor]);
	
	//Draw body color and shadow
	[p fill];
	
	//Clip to inside body
	[p addClip];
	
	//Unset shadow
	CGContextSetShadowWithColor(ctx, CGSizeZero, 0.f, NULL);
	
	//Draw overlay
	CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
	CGGradientRef gradient = CGGradientCreateWithColorComponents(space, (const CGFloat []){
		1.0f,1.0f,1.0f,1.0f,
		1.0f,1.0f,1.0f,0.35f,
		1.0f,1.0f,1.0f,0.0f,
		1.0f,1.0f,1.0f,0.0f,
		1.0f,1.0f,1.0f,0.35f,
	}, (const CGFloat []){
		0.0f,
		0.5f,
		0.51f,
		0.75f,
		1.0f,
	}, 5);
	
	CFRelease(space);
	
	CGContextSetAlpha(ctx, 0.5f);
	CGContextDrawLinearGradient(ctx, gradient,
								(CGPoint){.y = CGRectGetMinY(insetRect)},
								(CGPoint){.y = CGRectGetMaxY(insetRect)},
								kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
	CGGradientRelease(gradient);

	
	//Draw outside body clipped to inside body with shadow
	UIBezierPath *backwardsHugeSquare = [UIBezierPath bezierPathWithRect:bounds];
	[p appendPath:backwardsHugeSquare];	
	p.usesEvenOddFillRule = YES;
	
	CGContextSetShadowWithColor(ctx, CGSizeZero, 4.f, [[UIColor colorWithWhite:1.0f alpha:0.35f] CGColor]);
	[[UIColor whiteColor] setFill];
	[p fill];
			
	CGContextRestoreGState(ctx);

	//Clip to outside body
	[p addClip];

	//Draw second shadow
	p = [self pathForPatchBodyInRect:insetRect withTopPlugsWidth:topPlugsWidth bottomPlugsWidth:bottomPlugsWidth];

	[[UIColor colorWithWhite:0.0f alpha:0.8f] setStroke];
	
	CGContextSetLineWidth(ctx, 2.f);
	[p stroke];
	
	
}



- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	CGPoint p = [[touches anyObject] locationInView:self];
	if ([outputPlugStrip pointInside:[outputPlugStrip convertPoint:p fromView:self] withEvent:event] && self.patch.outputPorts.count > 0) {
		[graphView beginDraggingConnectionFromLocation:p inPatchView:self];
		draggingOutputConnection = YES;
	}
	if (draggable) {
		dragging = YES;
		[self sizeToFit];
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	if (draggingOutputConnection) {
		[graphView continueDraggingConnectionWithLocation:[[touches anyObject] locationInView:self] inPatchView:self];
	} else if (draggable && dragging) {
		UITouch *touch = [touches anyObject];
		CGPoint location = [touch locationInView:self];
		CGPoint previous = [touch previousLocationInView:self];
		CGPoint center = self.center;
		center.x += location.x - previous.x;
		center.y += location.y - previous.y;
		
		self.center = center;
		[self sizeToFit];
		self.patch.editorPosition = center;
		self.frame = CGRectIntegral(self.frame);
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
{
	if (draggingOutputConnection) {
		[graphView endDraggingConnectionWithLocation:[[touches anyObject] locationInView:self] inPatchView:self];
		draggingOutputConnection = NO;
	} if (draggable && dragging) {
		CGPoint center = self.center;
		self.center = center;
		self.frame = CGRectIntegral(self.frame);
		dragging = NO;
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if (draggingOutputConnection) {
		[graphView endDraggingConnectionWithLocation:[[touches anyObject] locationInView:self] inPatchView:self];
		draggingOutputConnection = NO;
	} if (draggable && dragging) {
		CGPoint center = self.center;
		self.center = center;
		self.frame = CGRectIntegral(self.frame);
		dragging = NO;
	}
}


#pragma mark -

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event;
{
	return [super pointInside:point withEvent:event] || [inputPlugStrip pointInside:[self convertPoint:point toView:inputPlugStrip] withEvent:event] || [outputPlugStrip pointInside:[self convertPoint:point toView:outputPlugStrip] withEvent:event];
}

- (WMPort *)inputPortAtPoint:(CGPoint)inPoint inView:(UIView *)inView;
{
	CGPoint point = [inputPlugStrip convertPoint:inPoint fromView:inView];
	BOOL inInputs = [inputPlugStrip pointInside:point withEvent:nil];
	
	if (inInputs && patch.inputPorts.count > 0) {
		NSUInteger portIndex = [inputPlugStrip portIndexAtPoint:point];
		return [self.patch.inputPorts objectAtIndex:portIndex];
	}
	return nil;
}


- (WMPort *)outputPortAtPoint:(CGPoint)inPoint inView:(UIView *)inView;
{
	CGPoint point = [outputPlugStrip convertPoint:inPoint fromView:inView];
	BOOL inInputs = [outputPlugStrip pointInside:point withEvent:nil];
	
	if (inInputs && patch.outputPorts.count > 0) {
		NSUInteger portIndex = [outputPlugStrip portIndexAtPoint:point];
		return [self.patch.outputPorts objectAtIndex:portIndex];
	}
	return nil;
}

- (CGPoint)pointForInputPort:(WMPort *)inputPort;
{
	WMPort *port = [self.patch inputPortWithKey:inputPort.key];
	if (port) {
		NSUInteger idx = [patch.inputPorts indexOfObject:port];
		if (idx != NSNotFound) {
			return [self.superview convertPoint:[inputPlugStrip pointForPortIndex:idx] fromView:inputPlugStrip];
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
			return [self.superview convertPoint:[outputPlugStrip pointForPortIndex:idx] fromView:outputPlugStrip];
		}
	}
	return patch.editorPosition;
}

- (void)inputsTapped:(UITapGestureRecognizer *)inR;
{
	[graphView inputPortStripTappedWithRect:inputPlugStrip.frame patchView:self];
}

#pragma mark - Menu


- (BOOL)canBecomeFirstResponder;
{
	return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
	return action == @selector(delete:) || (action == @selector(showSettings:) && [patch hasSettings]);
}

- (void)tapped:(UITapGestureRecognizer *)inR;
{
	UIMenuItem *settingsItem = [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"Settings…", nil) action:@selector(showSettings:)];
	
	[UIMenuController sharedMenuController].menuItems = [NSArray arrayWithObject:settingsItem];
	[[UIMenuController sharedMenuController] setTargetRect:label.frame inView:self];
	[[UIMenuController sharedMenuController] setMenuVisible:YES animated:YES];
	
	[self becomeFirstResponder];
	
}

- (void)delete:(id)sender;
{
	[graphView removePatch:self.patch];
}

- (void)showSettings:(id)sender;
{
	[graphView showSettingsForPatchView:self];
}

@end
