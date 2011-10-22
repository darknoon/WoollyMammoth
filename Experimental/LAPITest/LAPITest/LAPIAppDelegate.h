//
//  LAPIAppDelegate.h
//  LAPITest
//
//  Created by Andrew Pouliot on 9/28/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LAPIViewController;

@interface LAPIAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) LAPIViewController *viewController;

@end
