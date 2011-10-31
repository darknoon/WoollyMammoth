//
//  WMNumberInputPortCell.h
//  WMEdit
//
//  Created by Andrew Pouliot on 7/26/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMInputPortCell.h"

@interface WMNumberInputPortCell : WMInputPortCell

@property (nonatomic, strong) IBOutlet UISlider *valueSlider;
@property (nonatomic, strong) IBOutlet UITextField *textField;

- (IBAction)changeValue:(id)sender;

@end
