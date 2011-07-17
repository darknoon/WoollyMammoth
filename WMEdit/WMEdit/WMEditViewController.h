
//
//  WMEditViewController.h
//  WMEdit
//
//  Created by Andrew Pouliot on 7/15/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "WMGraphEditView.h"

@interface WMEditViewController : UIViewController

@property (nonatomic, retain) IBOutlet WMGraphEditView *graphView;

- (void)popupMenu;
@end
