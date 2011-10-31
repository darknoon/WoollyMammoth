//
//  WMNumberInputPortCell.m
//  WMEdit
//
//  Created by Andrew Pouliot on 7/26/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMNumberInputPortCell.h"

#import "WMNumberPort.h"

@implementation WMNumberInputPortCell {
	NSNumberFormatter *formatter;
}
@synthesize valueSlider;
@synthesize textField;

- (void)setPort:(WMPort *)inPort;
{
	[super setPort:inPort];
	
	WMNumberPort *port = (WMNumberPort *)inPort;

	if (!formatter) {
		formatter = [[NSNumberFormatter alloc] init];
		formatter.allowsFloats = YES;
	}
	textField.text = [formatter stringFromNumber:[[NSNumber alloc] initWithFloat:port.value]];

	
	valueSlider.minimumValue = port.minValue;
	valueSlider.maximumValue = port.maxValue;
	valueSlider.value = port.value;
}

- (IBAction)changeValue:(id)sender;
{
	WMNumberPort *port = (WMNumberPort *)self.port;
	if (sender == valueSlider) {
		[port setValue:[(UISlider *)sender value]];
		textField.text = [formatter stringFromNumber:[[NSNumber alloc] initWithFloat:port.value]];
	} else if (sender == textField) {
		//Validate input value
		float value = [(UISlider *)sender value];
		value = MAX(port.minValue, MIN(value, port.maxValue));
		[port setValue:value];
		valueSlider.value = value;
	}
}

@end
