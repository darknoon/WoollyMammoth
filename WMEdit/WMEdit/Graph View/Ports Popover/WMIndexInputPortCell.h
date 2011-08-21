//
//  WMIndexInputPortCell.h
//  WMEdit
//
//  Created by Andrew Pouliot on 8/21/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import "WMInputPortCell.h"

@interface WMIndexInputPortCell : WMInputPortCell <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField *textField;

- (IBAction)changeValue:(id)sender;

@end
