//
//  WMPatchView.m
//  WMEdit
//
//  Created by Andrew Pouliot on 7/15/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMPatchView.h"

#import "CGRoundRect.h"

@implementation WMPatchView
@synthesize name;
@synthesize dragging;
@synthesize draggable;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
	if (!self) return nil;
	
	self.opaque = NO;
	self.draggable = YES;
	
    return self;
}

- (void)dealloc
{
	[name release];
    [super dealloc];
}

- (void)drawRect:(CGRect)rect
{
	CGContextRef ctx = UIGraphicsGetCurrentContext();

	[[UIColor colorWithWhite:0.0f alpha:0.5f] setFill];
	CGContextAddRoundRect(ctx, self.bounds, 9.0f);
	CGContextFillPath(ctx);

	CGContextAddRoundRect(ctx, CGRectInset(self.bounds, 0.5f, 0.5f), 9.0f);
	CGContextStrokePath(ctx);
	
	[self.name drawInRect:self.bounds withFont:[UIFont boldSystemFontOfSize:14.f] lineBreakMode:UILineBreakModeMiddleTruncation alignment:UITextAlignmentCenter];
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
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if (draggable && dragging) {
		CGPoint center = self.center;
		self.center = center;
		dragging = NO;
	}
}


@end
