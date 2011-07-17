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
#import "WMPatchListTableViewController.h"
#import "WMGraphEditView.h"
#import "WMPatch.h"
#import "WMViewController.h"
#import "WMCompositionLibrary.h"
#import "WMCompositionLibraryViewController.h"


@implementation WMEditViewController {
	int keycnt; //TODO: better unique key system
	NSMutableDictionary *patchViewsByKey;
	
	CGPoint addLocation;
	UIPopoverController *addNodePopover;
	
	WMViewController *previewController;
	
	WMPatch *rootPatch; 
    WMGraphEditView *graphicView;
}

@synthesize graphView;

- (void)sharedInit;
{
	patchViewsByKey = [[NSMutableDictionary alloc] init];
	rootPatch = [[WMPatch alloc] initWithPlistRepresentation:nil];
	previewController = [[WMViewController alloc] initWithRootPatch:rootPatch];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;
{
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (!self) return nil;
	
	[self sharedInit];
	
	return self;
}

- (void)awakeFromNib;
{
	[self sharedInit];
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
	
	UILongPressGestureRecognizer *longPressRecognizer = [[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)]autorelease];
	[self.view addGestureRecognizer:longPressRecognizer];
	
    UIRotationGestureRecognizer *rotator = [[[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotatingGesture:)]autorelease];
    [self.view addGestureRecognizer:rotator];
	graphView.rootPatch = rootPatch;
	
	CGSize previewSize = (CGSize){.width = 300, .height = 200};
	CGRect bounds = self.view.bounds;
	previewController.view.frame = (CGRect){.origin.x = bounds.size.width - previewSize.width, .origin.y = bounds.size.height - previewSize.height, .size = previewSize};
	previewController.view.backgroundColor = [UIColor cyanColor];
	previewController.view.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
	[self.view addSubview:previewController.view];
}

- (void)addNodeAtLocation:(CGPoint)inPoint class:(NSString *)inClass;
{
	keycnt++;
	
	NSString *key = [NSString stringWithFormat:@"node-%d", keycnt];
	
	Class patchClass = NSClassFromString(inClass);
	if (patchClass) {
		WMPatch *patch = [[[patchClass alloc] initWithPlistRepresentation:nil] autorelease];
		patch.key = key;
		patch.editorPosition = inPoint;
		
		[graphView addPatch:patch];
	} else {
		NSLog(@"invalid class: %@", inClass);
	}
	
}

- (void)popupMenu:(CGPoint)origin {
    if (addNodePopover) {
        [addNodePopover dismissPopoverAnimated:NO];
        [addNodePopover release];
        addNodePopover = nil;
    }
    
    WMPatchListTableViewController *patchList = [[WMPatchListTableViewController alloc] initWithStyle:UITableViewStylePlain];
    patchList.delegate = (id<WMPatchListTableViewControllerDelegate>)self;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:patchList];
    addNodePopover = [[UIPopoverController alloc] initWithContentViewController:nav];
    addLocation = origin;
    [addNodePopover presentPopoverFromRect:(CGRect){.origin = addLocation} inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}


- (void)popupMenu {
    [self popupMenu:CGPointMake(self.view.bounds.size.width/3.0, self.view.bounds.size.height/2.0)];
}

- (void)checkPopover:(BOOL)animage {
    [addNodePopover dismissPopoverAnimated:animage];
    [addNodePopover release];
    addNodePopover = nil;
}

- (void)rotatingGesture:(UIRotationGestureRecognizer *)gesture {
    WMCompositionLibraryViewController *wm = [[[WMCompositionLibraryViewController alloc] init] autorelease];
    [self checkPopover:NO];
    addNodePopover = [[UIPopoverController alloc] initWithContentViewController:wm];
    CGPoint addLocation = [gesture locationInView:self.view];
    [addNodePopover presentPopoverFromRect:(CGRect){.origin = addLocation} inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)longPress:(UILongPressGestureRecognizer *)inR;
{
	if (inR.state == UIGestureRecognizerStateBegan) {
//        CGPoint p = [inR locationInView:graphView)];
        
        // for each of our little patch guys do
        //     - is P in bounds ?
        //      - if so, bail, otherwise fall through to the next line
        
        [self popupMenu];
	}
}
         

- (void)patchList:(WMPatchListTableViewController *)inPatchList selectedPatchClassName:(NSString *)inClassName;
{
	[self addNodeAtLocation:addLocation class:inClassName];
	[addNodePopover dismissPopoverAnimated:YES];
	[addNodePopover release];
	addNodePopover = nil;
}

- (void)viewWillAppear:(BOOL)inAnimated;
{
	[super viewWillAppear:inAnimated];
	[previewController viewWillAppear:inAnimated];
}

- (void)viewDidAppear:(BOOL)inAnimated;
{
	[super viewDidAppear:inAnimated];
	[previewController viewDidAppear:inAnimated];
}

- (void)viewDidDisappear:(BOOL)inAnimated;
{
	[super viewDidDisappear:inAnimated];
	[previewController viewDidDisappear:inAnimated];
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
