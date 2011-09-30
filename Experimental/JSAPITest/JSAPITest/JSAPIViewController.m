//
//  JSAPIViewController.m
//  JSAPITest
//
//  Created by Andrew Pouliot on 9/25/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import "JSAPIViewController.h"
#import "WMJavascript.h"

@implementation JSAPIViewController {
	WMJavascript *js;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
{
	js = [[WMJavascript alloc] init];
	
	NSURL *fileURL = [[NSBundle mainBundle] URLForResource:@"InputOutputTest" withExtension:@"js"];
	js.programText = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:NULL];
	[js run];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
	    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
	} else {
	    return YES;
	}
}

@end
