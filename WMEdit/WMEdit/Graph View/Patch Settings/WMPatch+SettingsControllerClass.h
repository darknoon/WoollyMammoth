//
//  WMPatch+SettingsControllerClass.h
//  WMEdit
//
//  Created by Andrew Pouliot on 7/27/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMPatch.h"

@protocol WMPatchSettingsController <NSObject>

- (id)initWithPatch:(WMPatch *)inPatch;

@property (nonatomic, retain) WMPatch *patch;

@end

@interface WMPatch (WMPatch_SettingsControllerClass)

//You should override this to return yes if you could create a settings controller for the patch when asked for -settingsController
- (BOOL)hasSettings;

//Creates an autoreleased instance of the appropriate settings controller.
//You should probably override this in your <BlahPatch>SettingsController.m to define it to create a <BlahPatch>SettingsController.
- (UIViewController<WMPatchSettingsController> *)settingsController;

@end
