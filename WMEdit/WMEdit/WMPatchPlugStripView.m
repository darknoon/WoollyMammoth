//
//  WMPatchPlugStripView.m
//  WMEdit
//
//  Created by Andrew Pouliot on 7/15/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMPatchPlugStripView.h"

#import "CGRoundRect.h"

#import "WMGraphEditView.h"

@implementation WMPatchPlugStripView
@synthesize inputCount;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
	if (!self) return nil;
	
	self.opaque = NO;
	
    return self;
}

- (void)setInputCount:(NSUInteger)inInputCount
{
	if (inputCount != inInputCount) {
		inputCount = inInputCount;
		[self setNeedsDisplay];
	}
}

- (CGSize)sizeThatFits:(CGSize)inSize;
{
	return (CGSize) {.width = leftOffset + leftOffset + offsetBetweenDots * inputCount, .height = plugstripHeight};
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGRect bounds = self.bounds;
	const CGFloat dotSize = 9.f;
	
	[[UIColor colorWithWhite:1.0f alpha:0.7f] setFill];
	CGContextAddRoundRect(ctx, bounds, bounds.size.height / 2);
	CGContextFillPath(ctx);
	
	[[UIColor blackColor] setFill];
	for (int i=0; i<inputCount; i++) {
		CGContextBeginPath(ctx);
		CGContextAddEllipseInRect(ctx, (CGRect){.origin.x = leftOffset + offsetBetweenDots * i, .origin.y = bounds.size.height / 2.f, .size.width = dotSize, .size.height = dotSize});
		CGContextFillPath(ctx);
	}
}

- (void)dealloc
{
    [super dealloc];
}

#pragma mark -

- (NSUInteger)portIndexAtPoint:(CGPoint)inPoint;
{
	if (inputCount > 0) {
		CGFloat offX = (inPoint.x - leftOffset) / offsetBetweenDots;
		int offXi = (int)roundf(offX);
		return MAX(0, MIN(offXi, inputCount - 1));
	}
	return NSNotFound;
}

- (CGPoint)pointForPortIndex:(NSUInteger)inIndex;
{
	if (inIndex != NSNotFound) {
		return (CGPoint){.x = leftOffset + inIndex * offsetBetweenDots, .y = plugstripHeight / 2.f};
	}
	return CGPointZero;
	
}

@end
