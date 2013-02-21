//
//  AppDelegate.m
//  SmoothHex
//
//  Created by Andrew Pouliot on 1/29/13.
//  Copyright (c) 2013 Darknoon. All rights reserved.
//

#import "AppDelegate.h"

#import "ViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	self.window.rootViewController = [[ViewController alloc] initWithNibName:nil bundle:nil];
	[self.window makeKeyAndVisible];
	return YES;
}

@end
