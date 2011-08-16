//
//  WMPatch+SettingsControllerClass.m
//  WMEdit
//
//  Created by Andrew Pouliot on 7/27/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMPatch+SettingsControllerClass.h"

@implementation WMPatch (WMPatch_SettingsControllerClass)

- (BOOL)hasSettings;
{
	return NO;
}

- (UIViewController<WMPatchSettingsController> *)settingsController;
{
	return nil;
}

@end