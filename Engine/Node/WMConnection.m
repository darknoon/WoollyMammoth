//
//  WMConnection.m
//  QCParse
//
//  Created by Andrew Pouliot on 4/12/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMConnection.h"


@implementation WMConnection
@synthesize sourceNode, sourcePort, destinationNode, destinationPort, name;

- (NSString *)description;
{
	return [NSString stringWithFormat:@"<%@: %p {%@ : %@ => %@ : %@ }>", NSStringFromClass([self class]), sourceNode, sourcePort, destinationNode, destinationPort];
}


@end
