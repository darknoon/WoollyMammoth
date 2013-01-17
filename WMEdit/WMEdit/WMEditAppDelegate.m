//
//  WMEditAppDelegate.m
//  WMEdit
//
//  Created by Andrew Pouliot on 7/15/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMEditAppDelegate.h"

#import <WMGraph/DNAssertionHandler.h>

@implementation WMEditAppDelegate

@synthesize window =_window;

@synthesize navController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	
	//Set our assertion handler
	[[[NSThread currentThread] threadDictionary] setObject:[[DNAssertionHandler alloc] init] forKey:NSAssertionHandlerKey];
	
    return YES;
}

@end
