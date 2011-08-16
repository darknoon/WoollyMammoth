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
	
	NSArray *portViews;
	
	UIImageView *highlight;

}
@synthesize connectionIndex;
@synthesize ports;
@synthesize connectablePorts;
@synthesize canConnect;

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

	highlight = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"plug-popover-highlight"]];
	[self addSubview:highlight];
	
    return self;
}

- (void)layoutSubviews;
{
	CGRect bounds = self.bounds;
	backgroundView.frame = (CGRect){0,0, bounds.size.width, backgroundHeight};
	
	CGFloat cwidth = 40;
	chevron.frame = (CGRect){(bounds.size.width-cwidth)/2, 73, cwidth, 32};
	
	title.frame = (CGRect){23,19, bounds.size.width - 44, 20};
	
	[portViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		UIView *pv = (UIView *)obj;
		pv.frame = (CGRect){insetLeft + idx * spacing, 45,  18, 19};
	}];
	
	CGSize hvs = highlight.frame.size;
	highlight.frame = (CGRect) {insetLeft - 50 + connectionIndex * spacing, 45 - 50, hvs.width, hvs.height};
	
	highlight.alpha = canConnect ? 1.0f : 0.2f;
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
	
	for (UIView *cv in portViews) {
		[cv removeFromSuperview];
	}
	NSMutableArray *pvm = [NSMutableArray array];
	for (WMPort *p in ports) {
		UIImageView *pv = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"plug-popover-dot"]];
		pv.alpha = [connectablePorts containsObject:p] ? 1.0f : 0.4f;
		[pvm addObject:pv];
		[self addSubview:pv];
	}
	portViews = pvm;
		
	[self bringSubviewToFront:highlight];

	[self setNeedsLayout];
}

- (void)setTargetPoint:(CGPoint)inPoint;
{
	inPoint.y -= 46;
	self.center = inPoint;
}

@end
