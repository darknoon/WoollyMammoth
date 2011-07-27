//
//  WMNumberInputPortCell.h
//  WMEdit
//
//  Created by Andrew Pouliot on 7/26/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMInputPortCell.h"

@interface WMNumberInputPortCell : WMInputPortCell

@property (nonatomic, retain) IBOutlet UISlider *valueSlider;

- (IBAction)changeValue:(id)sender;

@end
