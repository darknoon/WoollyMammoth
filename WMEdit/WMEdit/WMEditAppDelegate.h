//
//  WMEditAppDelegate.h
//  WMEdit
//
//  Created by Andrew Pouliot on 7/15/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WMEditViewController;

@interface WMEditAppDelegate : NSObject <UIApplicationDelegate> {

}

@property (nonatomic, strong) IBOutlet UIWindow *window;


@property (nonatomic, strong) IBOutlet UINavigationController *navController;

@property (nonatomic, strong) IBOutlet WMEditViewController *viewController;

@end
