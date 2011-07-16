//
//  WMEditViewController.m
//  WMEdit
//
//  Created by Andrew Pouliot on 7/15/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMEditViewController.h"

#import "WMPatchView.h"

@implementation WMEditViewController

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
	[self.view addGestureRecognizer:longPressRecognizer];
}

- (void)addNodeAtLocation:(CGPoint)inPoint;
{
	WMPatchView *newNodeView = [[[WMPatchView alloc] initWithFrame:(CGRect){.origin.x = inPoint.x - 100, .origin.y = inPoint.y - 50, .size.width = 200, .size.height = 100}] autorelease];
	newNodeView.name = @"blah";
	[self.view addSubview:newNodeView];
}

- (void)longPress:(UILongPressGestureRecognizer *)inR;
{
	if (inR.state == UIGestureRecognizerStateRecognized) {
		[self addNodeAtLocation:[inR locationInView:self.view]];
	}
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

@end
