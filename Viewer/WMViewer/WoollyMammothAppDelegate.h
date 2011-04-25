//
//  WoollyMammothAppDelegate.h
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 9/27/10.
//  Copyright Darknoon 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WMViewController;
@class WMEngine;

@interface WoollyMammothAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    WMViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet WMViewController *viewController;

@end
