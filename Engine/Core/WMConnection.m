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

+ (WMConnection *)connection;
{
	return [[[self class] alloc] init];
}

- (BOOL)isEqual:(id)other;
{
	if ([other isKindOfClass:[WMConnection class]]) {
		WMConnection *otherConnection = (WMConnection *)other;
		return [sourceNode isEqualToString:otherConnection->sourceNode]
		&& [destinationNode isEqualToString:otherConnection->destinationNode]
		&& [sourcePort isEqualToString:otherConnection->sourcePort]
		&& [destinationPort isEqualToString:otherConnection->destinationPort];
	}
	return NO;
}

- (NSString *)description;
{
	return [NSString stringWithFormat:@"<%@: %p {%@ : %@ => %@ : %@ }>", NSStringFromClass([self class]), self, self.sourceNode, self.sourcePort, self.destinationNode, self.destinationPort];
}

@end
