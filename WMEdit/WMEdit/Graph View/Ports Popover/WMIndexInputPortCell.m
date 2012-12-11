//
//  WMIndexInputPortCell.m
//  WMEdit
//
//  Created by Andrew Pouliot on 8/21/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import "WMIndexInputPortCell.h"

#import <WMGraph/WMGraph.h>

@implementation WMIndexInputPortCell {
	NSNumberFormatter *formatter;
}

@synthesize textField;

- (void)setPort:(WMPort *)inPort;
{
	[super setPort:inPort];
	
	if (!formatter) {
		formatter = [[NSNumberFormatter alloc] init];
		formatter.allowsFloats = NO;
	}
	textField.text = [formatter stringFromNumber:[[NSNumber alloc] initWithUnsignedInteger:((WMIndexPort *)inPort).index]];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;
{
	//Only allow
	NSCharacterSet *charset = [NSCharacterSet decimalDigitCharacterSet];
	for (int i=0; i<string.length; i++) {
		if (![charset characterIsMember:[string characterAtIndex:i]]) {
			return NO;
		}
	}
	return YES;
}

- (IBAction)changeValue:(id)sender;
{
	UITextField *field = sender;
	NSNumber *number = [formatter numberFromString:field.text];
	
	[(WMIndexPort *)self.port setObjectValue:number];
	
	//Write back to field after validation...
	textField.text = [formatter stringFromNumber:[[NSNumber alloc] initWithUnsignedInteger:((WMIndexPort *)self.port).index]];
}


@end
