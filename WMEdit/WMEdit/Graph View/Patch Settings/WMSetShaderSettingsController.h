//
//  WMSetShaderSettingsController.h
//  WMEdit
//
//  Created by Andrew Pouliot on 7/27/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WMSetShader;

@interface WMSetShaderSettingsController : UIViewController

@property (nonatomic, retain) WMSetShader *patch;

@property (nonatomic) BOOL editingFragmentShader;

- (IBAction)toggleEditingVertexOrFragmentShader:(UISegmentedControl *)sender;
@property (retain, nonatomic) IBOutlet UITextView *textView;

@end
