//
//  WMCompatibilityMac.m
//  PizzaEngine
//
//  Created by Andrew Pouliot on 4/18/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import "WMCompatibilityMac.h"

NSString *NSStringFromCGPoint(CGPoint p)
{
    return NSStringFromPoint(NSPointFromCGPoint(p));
}

NSString *NSStringFromCGRect(CGRect r)
{
    return NSStringFromRect(NSRectFromCGRect(r));
}

NSString *NSStringFromCGSize(CGSize s)
{
    return NSStringFromSize(NSSizeFromCGSize(s));
}


CGPoint CGPointFromString(NSString *string)
{
	return NSPointFromString(string);
}

@implementation NSValue (NSValueUIGeometryExtensions)

+ (NSValue *)valueWithCGPoint:(CGPoint)point
{
    return [NSValue valueWithPoint:NSPointFromCGPoint(point)];
}

- (CGPoint)CGPointValue
{
    return NSPointToCGPoint([self pointValue]);
}

+ (NSValue *)valueWithCGRect:(CGRect)rect
{
    return [NSValue valueWithRect:NSRectFromCGRect(rect)];
}

- (CGRect)CGRectValue
{
    return NSRectToCGRect([self rectValue]);
}

+ (NSValue *)valueWithCGSize:(CGSize)size
{
    return [NSValue valueWithSize:NSSizeFromCGSize(size)];
}

- (CGSize)CGSizeValue
{
    return NSSizeToCGSize([self sizeValue]);
}

@end
