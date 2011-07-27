//
//  WMCustomPopoverView.m
//  WMEdit
//
//  Created by Andrew Pouliot on 7/26/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMCustomPopoverView.h"

@implementation WMCustomPopoverView {
	UIImageView *backgroundTop;         //0
	UIImageView *backgroundMiddleTop;   //1
	UIImageView *backgroundArrow;       //2
	UIImageView *backgroundMiddleBottom;//3
	UIImageView *backgroundBottom;      //4
}
@synthesize arrowDirection;
@synthesize arrowLocation;
@synthesize contentView;

static const CGFloat inset = 20.f;
static const CGFloat imageSize = 60.f;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
	if (!self) return nil;
	
	backgroundTop = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"black-popover-top"] stretchableImageWithLeftCapWidth:imageSize topCapHeight:0.0f]];
	[self addSubview:backgroundTop];
	
	backgroundMiddleTop = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"black-popover-middle"] stretchableImageWithLeftCapWidth:imageSize topCapHeight:0.0f]];
	[self addSubview:backgroundMiddleTop];
	
	backgroundArrow = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"black-popover-arrow-left"] stretchableImageWithLeftCapWidth:imageSize topCapHeight:0.0f]];
	[self addSubview:backgroundArrow];
	
	backgroundMiddleBottom = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"black-popover-middle"] stretchableImageWithLeftCapWidth:imageSize topCapHeight:0.0f]];
	[self addSubview:backgroundMiddleBottom];
	
	backgroundBottom = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"black-popover-bottom"] stretchableImageWithLeftCapWidth:imageSize topCapHeight:0.0f]];
	[self addSubview:backgroundBottom];
	
    return self;
}

- (void)setArrowDirection:(UIPopoverArrowDirection)inArrowDirection;
{
	arrowDirection = inArrowDirection;
	UIImage *image = arrowDirection == UIPopoverArrowDirectionLeft ? [UIImage imageNamed:@"black-popover-arrow-left"] : [UIImage imageNamed:@"black-popover-arrow-right"];
	backgroundArrow.image = [image stretchableImageWithLeftCapWidth:imageSize topCapHeight:0.0f];
}

- (CGRect)frameForPoint:(CGPoint)inPoint size:(CGSize)inDesiredSize inRect:(CGRect)inRect;
{
	return (CGRect){.origin.x = inPoint.x, .origin.y = inPoint.y - inDesiredSize.height / 2, .size = inDesiredSize};
}

- (void)setContentView:(UIView *)inContentView;
{
	if (contentView == inContentView) return;
	
	[contentView removeFromSuperview];
	[contentView release];
	contentView = [inContentView retain];
	
	if (contentView) [self addSubview:contentView];
}

- (void)layoutSubviews;
{
	CGRect outsideRect = CGRectInset(self.bounds, -20.f, -20.0f);

	CGRect frames[5];
	CGRect middle;

	//Carve off the top
	CGRectDivide(outsideRect, &frames[0], &middle, imageSize, CGRectMinYEdge);
	
	//Carve off the bottom from the middle
	CGRectDivide(middle, &frames[4], &middle, imageSize, CGRectMaxYEdge);
	
	//Now take the remaining space and position the arrow
	CGFloat arrowY = arrowLocation.y;
	NSLog(@"arrow Y coord in local: %f", arrowY);
	//Arrow
	frames[2] = (CGRect){.origin.x = outsideRect.origin.x, .origin.y = arrowY - imageSize, .size.width = outsideRect.size.width, .size.height = imageSize};
	//Above arrow
	frames[1] = (CGRect){.origin.x = outsideRect.origin.x, .origin.y = CGRectGetMaxY(frames[0]), .size.width = outsideRect.size.width, .size.height = CGRectGetMinY(frames[2]) - CGRectGetMaxY(frames[0])};
	//Below arrow
	frames[3] = (CGRect){.origin.x = outsideRect.origin.x, .origin.y = CGRectGetMaxY(frames[2]), .size.width = outsideRect.size.width, .size.height = CGRectGetMaxY(middle) - CGRectGetMaxY(frames[2])};
	
	backgroundTop.frame = frames[0];
	backgroundMiddleTop.frame = frames[1];
	backgroundArrow.frame = frames[2];
	backgroundMiddleBottom.frame = frames[3];
	backgroundBottom.frame = frames[4];
	
	contentView.frame = self.bounds;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event;
{
	return YES;
}

@end
