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
- (BOOL)saveComposition;

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
@synthesize titleLabel;
@synthesize addNodeRecognizer;

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
	[self addChildViewController:previewController];
	
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
	
	graphView.rootPatch = rootPatch;
	
	CGRect bounds = self.view.bounds;
	previewController.view.frame = (CGRect){.origin.x = bounds.size.width - previewSize.width, .origin.y = bounds.size.height - previewSize.height, .size = previewSize};
	previewController.view.backgroundColor = [UIColor blackColor];
	previewController.view.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
	[self.view addSubview:previewController.view];
	
	UITapGestureRecognizer *enlargeRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(togglePreviewFullscreen:)] autorelease];
	[previewController.view addGestureRecognizer:enlargeRecognizer];
	
    self.navigationItem.titleView = titleLabel;
    UITapGestureRecognizer *editRecognizer = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(editCompositionNameAction:)] autorelease];
	[titleLabel addGestureRecognizer:editRecognizer];
    titleLabel.text = fileURL ? [[WMCompositionLibrary compositionLibrary] shortNameFromURL:fileURL] : NSLocalizedString(@"Tap to name Composition", nil);
	[self addPatchViews];
}

- (void)textFieldDidEndEditing:(UITextField *)textField;             // may be called if forced even if shouldEndEditing returns NO (e.g. view removed from window) or endEditing:YES called
{
    NSString *shortName = textField.text;
    if (shortName.length > 0) {
        if (!fileURL) {
            fileURL = [[[WMCompositionLibrary compositionLibrary] URLForResourceShortName:shortName] retain];
            if ([self saveComposition]) self.titleLabel.text = shortName;
        } else {
            if (![shortName isEqualToString:[[[fileURL absoluteString] lastPathComponent] stringByDeletingPathExtension]]) {
                if ([[WMCompositionLibrary compositionLibrary] renameComposition:fileURL to:shortName]) {
                    self.titleLabel.text = shortName;
                    fileURL = [[[WMCompositionLibrary compositionLibrary] URLForResourceShortName:shortName] retain];
                }
            }
        }
    }
    [textField removeFromSuperview];
}
    
    
- (BOOL)textFieldShouldReturn:(UITextField *)textField;              // called when 'return' key pressed. return NO to ignore.
{
    [textField endEditing:YES];
    return NO;
}

- (IBAction)editCompositionNameAction:(id)sender {
    UITextField *tf = [[UITextField alloc] initWithFrame:titleLabel.frame];
    tf.backgroundColor = [UIColor whiteColor];
    tf.textAlignment = UITextAlignmentCenter;
    tf.textColor = [UIColor blackColor];
    tf.font = [UIFont boldSystemFontOfSize:18.0];
    tf.delegate = self;
    [[titleLabel superview] addSubview:tf];
    [tf becomeFirstResponder];
    [tf release]; // give me ARC - I love it so much now and can't stand this bs anymore!
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

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)inR shouldReceiveTouch:(UITouch *)inTouch;
{
	if (inR == addNodeRecognizer) {
		//Don't recognize taps in the top of the window, as these should hit the top bar
		return [inTouch locationInView:self.view].y > 44.f;
	}
	return YES;
}

- (void)addNode:(UITapGestureRecognizer *)inR;
{
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


- (void)patchList:(WMPatchListTableViewController *)inPatchList selectedPatchClassName:(NSString *)inClassName;
{
	[self addNodeAtLocation:addLocation class:inClassName];
	[addNodePopover dismissPopoverAnimated:YES];
	[addNodePopover release];
	addNodePopover = nil;
}

- (BOOL)saveComposition;
{
	//Save
	return [[WMCompositionLibrary compositionLibrary] saveComposition:rootPatch image:[previewController screenshotImage] toURL:self.fileURL];
}

- (IBAction)close:(id)sender;
{
	[self saveComposition];
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
	self.addNodeRecognizer = nil;
	self.patchesButton = nil;
	self.libraryButton = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

@end
