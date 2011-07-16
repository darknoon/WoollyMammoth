//
//  WMEditViewController.m
//  WMEdit
//
//  Created by Andrew Pouliot on 7/15/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMEditViewController.h"

#import "WMPatchView.h"

#import "WMPatchConnectionsView.h"

#import "WMGraphEditView.h"
#import "WMPatch.h"

@implementation WMEditViewController {
	int keycnt; //TODO: better unique key system
	NSMutableDictionary *patchViewsByKey;
	
	WMPatch *rootPatch;
}
@synthesize graphView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (!self) return nil;
	
	patchViewsByKey = [[NSMutableDictionary alloc] init];
	rootPatch = [[WMPatch alloc] initWithPlistRepresentation:nil];
	
	return self;
}

- (void)awakeFromNib;
{
	patchViewsByKey = [[NSMutableDictionary alloc] init];
	rootPatch = [[WMPatch alloc] initWithPlistRepresentation:nil];
}

- (void)dealloc
{
	[graphView release];
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
	
	graphView.rootPatch = rootPatch;
}

- (void)addNodeAtLocation:(CGPoint)inPoint;
{
	keycnt++;
	
	NSString *key = [NSString stringWithFormat:@"node-%d", keycnt];
		
	WMPatch *patch = [[[WMPatch alloc] initWithPlistRepresentation:nil] autorelease];
	patch.key = key;
	patch.editorPosition = inPoint;
	
	[graphView addPatch:patch];
}

- (void)longPress:(UILongPressGestureRecognizer *)inR;
{
	if (inR.state == UIGestureRecognizerStateBegan) {
		[self addNodeAtLocation:[inR locationInView:self.view]];
	}
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
	self.graphView = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

@end
