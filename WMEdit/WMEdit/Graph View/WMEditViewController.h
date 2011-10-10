
//
//  WMEditViewController.h
//  WMEdit
//
//  Created by Andrew Pouliot on 7/15/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "WMGraphEditView.h"

@class WMBundleDocument;

@interface WMEditViewController : UIViewController <UITextFieldDelegate>

//nil == new document
- (id)initWithDocument:(WMBundleDocument *)inDocument;

@property (nonatomic, strong) WMBundleDocument *document;

@property (nonatomic, strong) IBOutlet WMGraphEditView *graphView;
@property (nonatomic, strong) IBOutlet UIButton *libraryButton;
@property (nonatomic, strong) IBOutlet UIButton *patchesButton;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;

@property (nonatomic, strong) IBOutlet UIGestureRecognizer *addNodeRecognizer;

//Indicate that a change has been made and the document is dirty
- (void)markDocumentDirty;

- (IBAction)close:(id)sender;
- (IBAction)addNode:(UITapGestureRecognizer *)inR;
- (IBAction)editCompositionNameAction:(id)sender;

//TODO: can we improve the api for communication between WMPatchView and WMEditViewController to remove glue code in WMGraphEditView
- (void)inputPortStripTappedWithRect:(CGRect)inInputPortsRect patchView:(WMPatchView *)inPatchView;
- (void)showSettingsForPatchView:(WMPatchView *)inPatchView;

@end
