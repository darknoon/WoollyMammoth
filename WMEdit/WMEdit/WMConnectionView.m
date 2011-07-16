//
//  WMConnectionView.m
//  WMEdit
//
//  Created by Andrew Pouliot on 7/16/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMConnectionView.h"

#import <QuartzCore/QuartzCore.h>

const CGFloat lineWidth = 8.f;

@implementation WMConnectionView  {
    CALayer *lineLayer;
    CALayer *shadowLayer;
}
@synthesize startPoint, endPoint;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
	if (!self) return nil;
	
	shadowLayer = [[CALayer alloc] init];
	shadowLayer.contents = (id)[[UIImage imageNamed:@"connection-shadow"] CGImage];
	[self.layer addSublayer:shadowLayer];

	lineLayer = [[CALayer alloc] init];
	lineLayer.contents = (id)[[UIImage imageNamed:@"connection-white"] CGImage];
	[self.layer addSublayer:lineLayer];
	
	
    return self;
}

- (void)dealloc
{
	[shadowLayer release];
	[lineLayer release];
    [super dealloc];
}

- (void)adjustFrame;
{
	CGFloat minx = MIN(startPoint.x, endPoint.x);
	CGFloat maxx = MAX(startPoint.x, endPoint.x);
	
	CGFloat miny = MIN(startPoint.y, endPoint.y);
	CGFloat maxy = MAX(startPoint.y, endPoint.y);

	self.frame = (CGRect){.origin.x = minx, .origin.y = miny, .size.width = maxx - minx, .size.height = maxy - miny};
}

- (void)setStartPoint:(CGPoint)inStartPoint;
{
	startPoint = inStartPoint;
	[self adjustFrame];
}

- (void)setEndPoint:(CGPoint)inEndPoint;
{
	endPoint = inEndPoint;
	[self adjustFrame];
}

- (void)layoutSubviews;
{
	[CATransaction begin];
	[CATransaction setDisableActions:YES];
	
	float radians = - atan2f(endPoint.x - startPoint.x, endPoint.y - startPoint.y);
	float length = sqrtf( (endPoint.x - startPoint.x)*(endPoint.x - startPoint.x) + (endPoint.y - startPoint.y)*(endPoint.y - startPoint.y) );
	
	lineLayer.position = [self convertPoint:startPoint fromView:self.superview];
	lineLayer.anchorPoint = (CGPoint){.x = 0.5f, .y = 0.0f};
	lineLayer.bounds = (CGRect){.origin.x = -lineWidth, .size.width = lineWidth, .size.height = length};
	lineLayer.transform = CATransform3DMakeRotation(radians, 0, 0, 1);

	CGPoint p = lineLayer.position;
	p.y += 2;
	shadowLayer.position = p;
	shadowLayer.anchorPoint = (CGPoint){.x = 0.5f, .y = 0.0f};
	shadowLayer.bounds = (CGRect){.origin.x = -lineWidth, .size.width = lineWidth, .size.height = length};
	shadowLayer.transform = CATransform3DMakeRotation(radians, 0, 0, 1);
	
	[CATransaction commit];

}

@end
