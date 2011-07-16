/*
 *  CGRoundRect.c
 *  yap-iphone
 *
 *  Created by Andrew Pouliot on 9/15/10.
 *  Copyright 2010 Yap.tv, Inc. All rights reserved.
 *
 */

#include "CGRoundRect.h"
#include "math.h"

void CGContextAddRoundRect(CGContextRef context, CGRect rect, float radius)
{
	if (radius > rect.size.height / 2.f) radius = rect.size.height / 2.f;
	CGContextMoveToPoint(context, rect.origin.x, rect.origin.y + radius);
	CGContextAddLineToPoint(context, rect.origin.x, rect.origin.y + rect.size.height - radius);
	CGContextAddArc(context, rect.origin.x + radius, rect.origin.y + rect.size.height - radius, 
					radius, M_PI, M_PI_2, 1);
	CGContextAddLineToPoint(context, rect.origin.x + rect.size.width - radius, 
							rect.origin.y + rect.size.height);
	CGContextAddArc(context, rect.origin.x + rect.size.width - radius, 
					rect.origin.y + rect.size.height - radius, radius, M_PI_2, 0.0f, 1);
	CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, rect.origin.y + radius);
	CGContextAddArc(context, rect.origin.x + rect.size.width - radius, rect.origin.y + radius, 
					radius, 0.0f, -M_PI_2, 1);
	CGContextAddLineToPoint(context, rect.origin.x + radius, rect.origin.y);
	CGContextAddArc(context, rect.origin.x + radius, rect.origin.y + radius, radius, 
					-M_PI_2, M_PI, 1);
}


void CGPathAddRoundRect (CGMutablePathRef path, const CGAffineTransform *m, CGRect rect, float radius)
{
	if (radius > rect.size.height / 2.f) radius = rect.size.height / 2.f;
	CGPathMoveToPoint(path, m, rect.origin.x, rect.origin.y + radius);
	CGPathAddLineToPoint(path, m, rect.origin.x, rect.origin.y + rect.size.height - radius);
	CGPathAddArc(path, m, rect.origin.x + radius, rect.origin.y + rect.size.height - radius, radius, M_PI, M_PI_2, 1);
	CGPathAddLineToPoint(path, m, rect.origin.x + rect.size.width - radius, rect.origin.y + rect.size.height);
	CGPathAddArc(path, m, rect.origin.x + rect.size.width - radius, rect.origin.y + rect.size.height - radius, radius, M_PI_2, 0.0f, 1);
	CGPathAddLineToPoint(path, m, rect.origin.x + rect.size.width, rect.origin.y + radius);
	CGPathAddArc(path, m, rect.origin.x + rect.size.width - radius, rect.origin.y + radius, radius, 0.0f, -M_PI_2, 1);
	CGPathAddLineToPoint(path, m, rect.origin.x + radius, rect.origin.y);
	CGPathAddArc(path, m, rect.origin.x + radius, rect.origin.y + radius, radius, -M_PI_2, M_PI, 1);
	
}