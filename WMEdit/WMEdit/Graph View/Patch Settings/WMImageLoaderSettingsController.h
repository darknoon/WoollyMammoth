//
//  WMImageLoaderSettingsController.h
//  WMEdit
//
//  Created by Andrew Pouliot on 8/1/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "WMPatch+SettingsControllerClass.h"
#import "WMImageLoader.h"

@class WMEditViewController;

@interface WMImageLoaderSettingsController : UIViewController <WMPatchSettingsController, UINavigationControllerDelegate, UIImagePickerControllerDelegate> {
	UIImageView *imageView;
}


- (id)initWithPatch:(WMImageLoader *)inPatch;

@property (nonatomic, retain) WMImageLoader *patch;
@property (retain, nonatomic) IBOutlet UIImageView *imageView;

- (IBAction)choosePhoto:(id)sender;

@end
