
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

@interface WMEditViewController : UIViewController <UITextFieldDelegate>

//nil == new document
- (id)initWithPatch:(WMPatch *)inPatch fileURL:(NSURL *)inURL;

@property (nonatomic, readonly) NSURL *fileURL;

@property (nonatomic, retain) IBOutlet WMGraphEditView *graphView;
@property (nonatomic, retain) IBOutlet UIButton *libraryButton;
@property (nonatomic, retain) IBOutlet UIButton *patchesButton;
@property (nonatomic, retain) IBOutlet UILabel *titleLabel;

@property (nonatomic, retain) IBOutlet UIGestureRecognizer *addNodeRecognizer;


- (IBAction)close:(id)sender;
- (IBAction)addNode:(UITapGestureRecognizer *)inR;
- (IBAction)editCompositionNameAction:(id)sender;

- (void)inputPortStripTappedWithRect:(CGRect)inInputPortsRect patchView:(WMPatchView *)inPatchView;

@end
