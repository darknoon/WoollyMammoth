//
//  WMNumberInputPortCell.m
//  WMEdit
//
//  Created by Andrew Pouliot on 7/26/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMNumberInputPortCell.h"

#import "WMNumberPort.h"

@implementation WMNumberInputPortCell
@synthesize valueSlider;

- (void)setPort:(WMPort *)inPort;
{
	[super setPort:inPort];
	
	valueSlider.value = [(WMNumberPort *)inPort value];
}

- (IBAction)changeValue:(id)sender;
{
	[(WMNumberPort *)self.port setValue:[(UISlider *)sender value]];
}

@end
