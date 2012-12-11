//
//  WMNumberInputPortCell.m
//  WMEdit
//
//  Created by Andrew Pouliot on 7/26/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMBooleanInputPortCell.h"

#import <WMGraph/WMGraph.h>

@implementation WMBooleanInputPortCell {
	NSNumberFormatter *formatter;
}
@synthesize segmentedControl = _segmentedControl;
@synthesize textField;

- (void)setPort:(WMPort *)inPort;
{
	[super setPort:inPort];
	
	WMBooleanPort *port = (WMBooleanPort *)inPort;

	if (!formatter) {
		formatter = [[NSNumberFormatter alloc] init];
		formatter.allowsFloats = YES;
	}
	textField.text = [formatter stringFromNumber:port.objectValue];

	_segmentedControl.selectedSegmentIndex = port.value ? 1 : 0;
}

- (IBAction)changeValue:(id)sender;
{
	WMBooleanPort *port = (WMBooleanPort *)self.port;
	port.value = _segmentedControl.selectedSegmentIndex > 0;
}

@end
