//
//  WoollyMammothAppDelegate.m
//  WoollyMammoth
//
//  Created by Andrew Pouliot on 9/27/10.
//  Copyright Darknoon 2010. All rights reserved.
//

#import "WoollyMammothAppDelegate.h"
#import "EAGLView.h"

#import "WMEngine.h"
#import "WMViewController.h"

#import "DNAssertionHandler.h"

@implementation WoollyMammothAppDelegate

@synthesize window;
@synthesize viewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
{
	[window makeKeyWindow];
	
	//Set our assertion handler
	[[[NSThread currentThread] threadDictionary] setObject:[[DNAssertionHandler alloc] init] forKey:NSAssertionHandlerKey];
		
	return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Handle any background procedures not related to animation here.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Handle any foreground procedures not related to animation here.
}

@end
