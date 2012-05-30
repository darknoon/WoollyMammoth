//
//  WMNumberInputPortCell.h
//  WMEdit
//
//  Created by Andrew Pouliot on 7/26/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMInputPortCell.h"

@interface WMBooleanInputPortCell : WMInputPortCell

@property (nonatomic, strong) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic, strong) IBOutlet UITextField *textField;

- (IBAction)changeValue:(id)sender;

@end
