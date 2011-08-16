//
//  WMInputPortCell.m
//  WMEdit
//
//  Created by Andrew Pouliot on 7/26/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMInputPortCell.h"

@implementation WMInputPortCell
@synthesize nameLabel;
@synthesize port;

- (void)setPort:(WMPort *)inPort;
{
	if (port == inPort) return;

	//TODO: observe external value changes
	
	port = inPort;
	
	nameLabel.text = inPort.name;
}

@end
