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

#import "WMPatchCategoryListTableViewController.h"
#import "WMPatchListTableViewController.h"
#import "WMGraphEditView.h"
#import "WMPatch.h"
#import "WMViewController.h"

#import "WMCompositionLibrary.h"

const CGSize previewSize = (CGSize){.width = 300, .height = 200};


@interface WMEditViewController ()
- (void)addPatchViews;
@end

@implementation WMEditViewController {
	NSMutableDictionary *patchViewsByKey;
	
	NSURL *fileURL;
	
	CGPoint addLocation;
	UIPopoverController *addNodePopover;
	
	BOOL previewFullScreen;
	WMViewController *previewController;
	
	WMPatch *rootPatch; 
    WMGraphEditView *graphicView;
    
}

@synthesize graphView;
@synthesize libraryButton;
@synthesize patchesButton;
@synthesize fileURL;

- (id)initWithPatch:(WMPatch *)inPatch fileURL:(NSURL *)inURL
{
	self = [super initWithNibName:@"WMEditViewController" bundle:nil];
	if (!self) return nil;
	
	fileURL = [inURL retain];
	
	patchViewsByKey = [[NSMutableDictionary alloc] init];
	
	if (inPatch) {
		rootPatch = [inPatch retain];
	} else {
		rootPatch = [[WMPatch alloc] initWithPlistRepresentation:nil];
	}
	rootPatch.key = @"root";
	
	previewController = [[WMViewController alloc] initWithRootPatch:rootPatch];
	
	return self;
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
	
//    UISwipeGestureRecognizer *swipe = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swiperAction:)]autorelease];
//    [swipe setDirection:UISwipeGestureRecognizerDirectionRight];
//    [self.view addGestureRecognizer:swipe];
//    swipe = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swiperAction:)]autorelease];
//    [swipe setDirection:UISwipeGestureRecognizerDirectionLeft];
//    [self.view addGestureRecognizer:swipe];

	graphView.rootPatch = rootPatch;
	
	CGRect bounds = self.view.bounds;
	previewController.view.frame = (CGRect){.origin.x = bounds.size.width - previewSize.width, .origin.y = bounds.size.height - previewSize.height, .size = previewSize};
	previewController.view.backgroundColor = [UIColor blackColor];
	previewController.view.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
	[self.view addSubview:previewController.view];
	
	UITapGestureRecognizer *enlargeRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(togglePreviewFullscreen:)] autorelease];
	[previewController.view addGestureRecognizer:enlargeRecognizer];
	
	[self addPatchViews];
}

- (void)togglePreviewFullscreen:(UITapGestureRecognizer *)inR;
{
	CGRect bounds = self.view.bounds;
	previewFullScreen = !previewFullScreen;
	[UIView animateWithDuration:0.2 animations:^(void) {
		if (previewFullScreen) {
			previewController.view.frame = bounds;
		} else {
			previewController.view.frame = (CGRect){.origin.x = bounds.size.width - previewSize.width, .origin.y = bounds.size.height - previewSize.height, .size = previewSize};
		}
	}];
}


- (void)addPatchViews;
{
	for (WMPatch *child in rootPatch.children) {
		[graphView addPatch:child];
	}
}

- (void)addNodeAtLocation:(CGPoint)inPoint class:(NSString *)inClass;
{	
	Class patchClass = NSClassFromString(inClass);
	if (patchClass) {
		WMPatch *patch = [[[patchClass alloc] initWithPlistRepresentation:nil] autorelease];
		patch.editorPosition = inPoint;
		
		[graphView addPatch:patch];
	} else {
		NSLog(@"invalid class: %@", inClass);
	}	
}

- (void)checkPopover:(BOOL)animage {
    [addNodePopover dismissPopoverAnimated:animage];
    [addNodePopover release];
    addNodePopover = nil;
}


- (void)swiperAction:(UISwipeGestureRecognizer *)gesture {
}

- (void)longPress:(UILongPressGestureRecognizer *)inR;
{
	if (inR.state == UIGestureRecognizerStateBegan) {
		if (addNodePopover) {
			[addNodePopover dismissPopoverAnimated:NO];
			[addNodePopover release];
		}
		
		WMPatchCategoryListTableViewController *patchCategoryList = [[WMPatchCategoryListTableViewController alloc] initWithStyle:UITableViewStylePlain];
		patchCategoryList.delegate = (id<WMPatchCategoryListTableViewControllerDelegate>)self;
		UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:patchCategoryList];
		addNodePopover = [[UIPopoverController alloc] initWithContentViewController:nav];
		addLocation = [inR locationInView:self.view];
		[addNodePopover presentPopoverFromRect:(CGRect){.origin = addLocation} inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	}
}
         

- (void)patchList:(WMPatchListTableViewController *)inPatchList selectedPatchClassName:(NSString *)inClassName;
{
	[self addNodeAtLocation:addLocation class:inClassName];
	[addNodePopover dismissPopoverAnimated:YES];
	[addNodePopover release];
	addNodePopover = nil;
}

- (void)save;
{
	//Save
	[[WMCompositionLibrary compositionLibrary] saveComposition:rootPatch image:[previewController screenshotImage] toURL:self.fileURL];
}

- (IBAction)close:(id)sender;
{
	[self save];
	[self.navigationController popViewControllerAnimated:YES];
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

- (void)viewWillDisappear:(BOOL)inAnimated;
{
	[super viewWillDisappear:inAnimated];
	[previewController viewWillDisappear:inAnimated];
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
