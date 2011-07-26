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
	
	UIImageView *background = [[[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"plugstrip-stretchable"] stretchableImageWithLeftCapWidth:11.f topCapHeight:0.f]] autorelease];
	background.frame = self.bounds;
	background.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self addSubview:background];
	
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
	if (inputCount > 0) {
		return (CGSize) {.width = leftOffset * 2.f + offsetBetweenDots * (inputCount - 1), .height = plugstripHeight};
	} else {
		return CGSizeZero;
	}
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	CGRect bounds = self.bounds;
	const CGFloat dotSize = 9.f;
	
	[[UIColor blackColor] setFill];
	for (int i=0; i<inputCount; i++) {
		CGContextBeginPath(ctx);
		CGContextAddEllipseInRect(ctx, (CGRect){.origin.x = leftOffset + offsetBetweenDots * i - dotSize/2, .origin.y = bounds.size.height / 2.f - dotSize / 2.f, .size.width = dotSize, .size.height = dotSize});
		CGContextFillPath(ctx);
	}
}

- (void)dealloc
{
    [super dealloc];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event;
{
	return CGRectContainsPoint(CGRectInset(self.bounds, -20, -10), point);
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
