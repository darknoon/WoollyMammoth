
//
//  WMEditViewController.h
//  WMEdit
//
//  Created by Andrew Pouliot on 7/15/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "WMGraphEditView.h"

@class WMCompositionLibraryViewController;

@interface WMEditViewController : UIViewController

@property (nonatomic, retain) IBOutlet WMGraphEditView *graphView;
@property (nonatomic, retain) IBOutlet UIButton *libraryButton;
@property (nonatomic, retain) IBOutlet UIButton *patchesButton;
@property (nonatomic, retain) WMCompositionLibraryViewController *compositionLibrary;

- (void)popupMenu;

- (IBAction)bringUpPatchesAction:(id)sender;
- (IBAction)bringUpLibraryAction:(id)sender;
@end
