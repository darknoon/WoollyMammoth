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

@implementation WMPatchView {
	WMPatchPlugStripView *inputPlugStrip;
	WMPatchPlugStripView *outputPlugStrip;
	WMPatch *patch;
}

@synthesize dragging;
@synthesize draggable;

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

    return self;
}

- (void)dealloc
{
	[patch release];
    [super dealloc];
}

- (WMPatch *)patch;
{
	return [[patch retain] autorelease];
}

- (void)layoutSubviews;
{
	inputPlugStrip.frame = (CGRect){.origin.x = 20.f, .origin.y = 0};
	[inputPlugStrip sizeToFit];

	outputPlugStrip.frame = (CGRect){.origin.x = 20.f, .origin.y = self.bounds.size.height - 20.f};
	[outputPlugStrip sizeToFit];
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
	
	CGRect labelFrame = UIEdgeInsetsInsetRect(self.bounds, (UIEdgeInsets){.top = 40.f, .bottom = 30.f});
	[self.patch.key drawInRect:labelFrame withFont:[UIFont boldSystemFontOfSize:14.f] lineBreakMode:UILineBreakModeMiddleTruncation alignment:UITextAlignmentCenter];
}

- (void)inputPlugsPan:(UIPanGestureRecognizer *)inR;
{
	NSLog(@"inputPlugsPan: %d", inR.state);
}

- (void)outputPlugsPan:(UIPanGestureRecognizer *)inR;
{
	
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


@end
