//
//  WMColorPort.m
//  Particulon
//
//  Created by Andrew Pouliot on 4/19/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMColorPort.h"


@implementation WMColorPort

- (NSString *)description;
{
	GLKVector4 rgba = self.v;
	return [NSString stringWithFormat:@"<%@ : %p>{r:%f g:%f b:%f, a:%f}", NSStringFromClass([self class]), self, rgba.r, rgba.g, rgba.b, rgba.a];
}


@end
