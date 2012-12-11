//
//  WMSetShaderSettingsController.h
//  WMEdit
//
//  Created by Andrew Pouliot on 7/27/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "WMPatch+SettingsControllerClass.h"
#import <WMGraph/WMSetShader.h>

@interface WMSetShaderSettingsController : UIViewController <WMPatchSettingsController>

@property (nonatomic, strong) WMSetShader *patch;

- (IBAction)toggleEditingVertexOrFragmentShader:(UISegmentedControl *)sender;
@property (strong, nonatomic) IBOutlet UITextView *textView;

@property (strong, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@end
