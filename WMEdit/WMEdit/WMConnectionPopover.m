//
//  WMConnectionPopover.m
//  WMEdit
//
//  Created by Andrew Pouliot on 7/17/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMConnectionPopover.h"

#import "WMPort.h"

const CGFloat insetLeft = 32;
const CGFloat spacing = 30;
const CGFloat backgroundHeight = 92;

@implementation WMConnectionPopover {
	UILabel *title;
	UIImageView *backgroundView;
	UIImageView *chevron;
}
@synthesize connectionIndex;
@synthesize ports;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
	if (!self) return nil;
	
	
	chevron = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"plug-popover-arrow"]];
	[self addSubview:chevron];

	backgroundView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"plug-popover"] stretchableImageWithLeftCapWidth:30.f topCapHeight:0.f]];
	[self addSubview:backgroundView];
	
	title = [[UILabel alloc] initWithFrame:CGRectZero];
	title.textAlignment = UITextAlignmentCenter;
	title.backgroundColor = [UIColor clearColor];
	title.textColor = [UIColor blackColor];
	title.alpha = 69.f;
	title.font = [UIFont boldSystemFontOfSize:14];
	[self addSubview:title];

    return self;
}
- (void)dealloc {
    [title release];
	[backgroundView release];
	[chevron release];
    [super dealloc];
}

- (void)layoutSubviews;
{
	CGRect bounds = self.bounds;
	backgroundView.frame = (CGRect){0,0, bounds.size.width, backgroundHeight};
	
	CGFloat cwidth = 40;
	chevron.frame = (CGRect){(bounds.size.width-cwidth)/2, 73, cwidth, 32};
	
	title.frame = (CGRect){23,19, bounds.size.width - 44, 30};
}

- (CGSize)sizeThatFits:(CGSize)size;
{
	size.height = backgroundHeight;
	size.width = insetLeft + spacing * ports.count + insetLeft;
	return size;
}

- (void)refresh;
{
	CGPoint center = self.center;
	[self sizeToFit];
	self.center = center;
	self.frame = CGRectIntegral(self.frame);
	
	title.text = [(WMPort *)[ports objectAtIndex:connectionIndex] name];
	
	[self setNeedsLayout];
}

- (void)setTargetPoint:(CGPoint)inPoint;
{
	inPoint.y -= 46;
	self.center = inPoint;
}

@end
