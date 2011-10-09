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
#import "WMCustomPopover.h"
#import "WMInputPortsController.h"
#import "WMPatch+SettingsControllerClass.h"
#import "WMBundleDocument.h"

#import "DNMemoryInfo.h"

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
	WMCustomPopover *inputPortsPopover;
	UIPopoverController *patchSettingsPopover;

	dispatch_source_t updateMemoryTimer;
	
	UIWindow *previewWindow;
	BOOL previewFullScreen;
	WMViewController *previewController;
	
	WMPatch *rootPatch; 
    WMGraphEditView *graphicView;
}

@synthesize document;
@synthesize graphView;
@synthesize libraryButton;
@synthesize patchesButton;
@synthesize titleLabel;
@synthesize addNodeRecognizer;

- (id)initWithDocument:(WMBundleDocument *)inDocument;
{
	self = [super init];
	if (!self) return nil;
	
	if (!inDocument) {
		return nil;
	}
	
	document = inDocument;

	patchViewsByKey = [[NSMutableDictionary alloc] init];
	
	rootPatch = document.rootPatch;
	rootPatch.key = @"root";

	return self;
}


- (NSURL *)fileURL;
{
	return document.fileURL;
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
	
	graphView.viewController = self;
	graphView.rootPatch = rootPatch;
	
	
	NSArray *possibleScreens = [UIScreen screens];
	__block UIScreen *externalScreen = nil;
	[possibleScreens enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		if (idx > 0) {
			externalScreen = obj;
			*stop = YES;
		}
	}];
	
	previewController = [[WMViewController alloc] initWithDocument:document];
	if (externalScreen) {
		previewWindow = [[UIWindow alloc] initWithFrame:externalScreen.applicationFrame];
		previewWindow.rootViewController = previewController;
		previewWindow.screen = externalScreen;
		previewWindow.hidden = NO;
	} else {
		[self addChildViewController:previewController];

		CGRect bounds = self.view.bounds;
		previewController.view.frame = (CGRect){.origin.x = bounds.size.width - previewSize.width, .origin.y = bounds.size.height - previewSize.height, .size = previewSize};
		previewController.view.backgroundColor = [UIColor blackColor];
		previewController.view.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
		[self.view addSubview:previewController.view];

		UITapGestureRecognizer *enlargeRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(togglePreviewFullscreen:)];
		[previewController.view addGestureRecognizer:enlargeRecognizer];
	}

	
    self.navigationItem.titleView = titleLabel;
    UITapGestureRecognizer *editRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(editCompositionNameAction:)];
	[titleLabel addGestureRecognizer:editRecognizer];
    titleLabel.text = document.localizedName;
	[self addPatchViews];
}

- (void)textFieldDidEndEditing:(UITextField *)textField;             // may be called if forced even if shouldEndEditing returns NO (e.g. view removed from window) or endEditing:YES called
{
    NSString *shortName = textField.text;
    if (shortName.length > 0) {
		NSURL *newFileURL = [[WMCompositionLibrary compositionLibrary] URLForResourceShortName:shortName];
		[document saveToURL:newFileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
			if (success) {
				titleLabel.text = document.localizedName;
			}
		}];
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
     // give me ARC - I love it so much now and can't stand this bs anymore!
}


- (void)togglePreviewFullscreen:(UITapGestureRecognizer *)inR;
{
	CGRect bounds = self.view.bounds;
	previewFullScreen = !previewFullScreen;
	[UIView animateWithDuration:0.2 animations:^(void) {
		if (previewFullScreen) {
			previewController.view.frame = bounds;
			previewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		} else {
			previewController.view.frame = (CGRect){.origin.x = bounds.size.width - previewSize.width, .origin.y = bounds.size.height - previewSize.height, .size = previewSize};
			previewController.view.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
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
		WMPatch *patch = [[patchClass alloc] initWithPlistRepresentation:nil];
		patch.editorPosition = inPoint;
		
		[graphView addPatch:patch];
	} else {
		NSLog(@"invalid class: %@", inClass);
	}	
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)inR shouldReceiveTouch:(UITouch *)inTouch;
{
	if (inR == addNodeRecognizer) {
		//Don't recognize taps in the top of the window, as these should hit the top bar
		return !inputPortsPopover && ![UIMenuController sharedMenuController].isMenuVisible && [inTouch locationInView:self.view].y > 44.f;
	}
	return YES;
}

- (void)addNode:(UITapGestureRecognizer *)inR;
{
	if (addNodePopover) {
		[addNodePopover dismissPopoverAnimated:NO];
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
	addNodePopover = nil;
}



- (void)inputPortStripTappedWithRect:(CGRect)inInputPortsRect patchView:(WMPatchView *)inPatchView;
{	
	if (inputPortsPopover) {
		[inputPortsPopover dismissPopoverAnimated:NO];
	}
	WMInputPortsController *content = [[WMInputPortsController alloc] initWithNibName:@"WMInputPortsController" bundle:nil];
	content.ports = inPatchView.patch.inputPorts;

	inputPortsPopover = [[WMCustomPopover alloc] initWithContentViewController:content];
	inputPortsPopover.delegate = (id<WMCustomPopoverDelegate>)self;
	[inputPortsPopover presentPopoverFromRect:[self.view convertRect:inInputPortsRect fromView:inPatchView] inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)showSettingsForPatchView:(WMPatchView *)inPatchView;
{
	if (inPatchView.patch.hasSettings && !patchSettingsPopover) {
		UIViewController<WMPatchSettingsController> *settingsController = [inPatchView.patch settingsController];
		settingsController.editViewController = self;
		
		UINavigationController *wrapper = [[UINavigationController alloc] initWithRootViewController:settingsController];
		
		patchSettingsPopover = [[UIPopoverController alloc] initWithContentViewController:wrapper];
		patchSettingsPopover.delegate = (id<UIPopoverControllerDelegate>)self;
		[patchSettingsPopover presentPopoverFromRect:inPatchView.frame inView:inPatchView.superview permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	}
}

- (void)customPopoverControllerDidDismissPopover:(WMCustomPopover *)inPopoverController;
{
	ZAssert(inputPortsPopover == inPopoverController, @"Wrong popover dismissed!");
	if (inputPortsPopover == inPopoverController) {
		inputPortsPopover = nil;
	}
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)inPopoverController;
{
	if (inPopoverController == patchSettingsPopover) {
		patchSettingsPopover = nil;
	} else if (inPopoverController == addNodePopover) {
		addNodePopover = nil;
	} else {
		NSLog(@"Unknown popover controller closed: %@", inPopoverController);
	}
}

- (IBAction)close:(id)sender;
{
	//Save
	NSLog(@"Attempting to close document: %@", document);
	[document closeWithCompletionHandler:^(BOOL success) {
		NSLog(@"Success in closing document: %@", document);
		[self.navigationController popViewControllerAnimated:YES];
	}];
}

- (void)viewWillAppear:(BOOL)inAnimated;
{
	[super viewWillAppear:inAnimated];
	[previewController viewWillAppear:inAnimated];
	
#if DEBUG
	if (!updateMemoryTimer) {
		updateMemoryTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
		//Every 1.0s +- 0.1s
		dispatch_source_set_timer(updateMemoryTimer, DISPATCH_TIME_NOW, NSEC_PER_SEC, NSEC_PER_SEC / 10);
		dispatch_source_set_event_handler(updateMemoryTimer, ^ {
			DNMemoryInfo info;
			if (DNMemoryGetInfo(&info)) {
				NSLog(@"memory free:%lld used:%lld", info.free, info.used);
			}
		});
	}
	dispatch_resume(updateMemoryTimer);
#endif
}

- (void)viewDidAppear:(BOOL)inAnimated;
{
	[super viewDidAppear:inAnimated];
	[previewController viewDidAppear:inAnimated];
}

- (void)viewWillDisappear:(BOOL)inAnimated;
{
#if DEBUG
	if (updateMemoryTimer) {
		dispatch_suspend(updateMemoryTimer);
	}
#endif
	[super viewWillDisappear:inAnimated];
	[previewController viewWillDisappear:inAnimated];
	[[UIMenuController sharedMenuController] setMenuVisible:NO];
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
