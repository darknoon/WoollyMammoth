//
//  WMDebugViewController.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 10/21/10.
//  Copyright 2010 Darknoon. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "BrowserViewController.h"

@class WMViewController;

@interface WMDebugViewController : UIViewController <BrowserViewControllerDelegate> {
	WMViewController *__weak parent;	
}

@property (nonatomic, weak) IBOutlet WMViewController *parent;

@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) IBOutlet UILabel *gameTitleLabel;
@property (nonatomic, strong) IBOutlet UILabel *gamePathLabel;

- (IBAction)close;
- (IBAction)reloadGame;
- (IBAction)loadRemote;

@end
