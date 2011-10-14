//
//  WMLuaSettingsController.h
//  WMEdit
//
//  Created by Andrew Pouliot on 10/13/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "WMPatch+SettingsControllerClass.h"
#import "WMLua.h"

@interface WMLuaSettingsController : UIViewController <WMPatchSettingsController>
@property (strong, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

- (IBAction)switchView:(UISegmentedControl *)sender;

@property (strong, nonatomic) WMLua *patch;
@property (strong, nonatomic) IBOutlet UITextView *textView;

@end
