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
#import "WEPopoverController.h"
#import "WMInputPortsController.h"
#import "WMPatch+SettingsControllerClass.h"
#import "WMBundleDocument.h"
#import "WMEngine.h"

#import "DNMemoryInfo.h"

#import "WMCompositionLibrary.h"


//HACK POPVIDEO HACK SUPPORT:

#import "DNZipArchive.h"
#import "ASIS3ObjectRequest.h"

//END HACK SUPPORT

const CGSize previewSize = (CGSize){.width = 300, .height = 200};


@interface WMEditViewController ()
- (void)addPatchViews;
- (IBAction)_hackUpload:(UIButton *)sender;

@end

@implementation WMEditViewController {
	NSMutableDictionary *patchViewsByKey;
	
	NSURL *fileURL;
	
	CGPoint addLocation;
	UIPopoverController *addNodePopover;	
	WEPopoverController *inputPortsPopover;
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
		if (obj != [UIScreen mainScreen]) {
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
		NSURL *oldFileURL = document.fileURL;
		NSURL *newFileURL = [[WMCompositionLibrary compositionLibrary] URLForResourceShortName:shortName];
		//TODO: should we duplicate document here?
		[document saveToURL:newFileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
			if (success) {
				titleLabel.text = document.localizedName;
			}
			//Now let the composition library know
			[[WMCompositionLibrary compositionLibrary] removeCompositionURL:oldFileURL];
			[[WMCompositionLibrary compositionLibrary] addCompositionURL:newFileURL];
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
}

- (void)markDocumentDirty;
{
	[self.document updateChangeCount:UIDocumentChangeDone];
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
		patch.editorPosition = [graphView editorPositionForPoint:[graphView convertPoint:inPoint fromView:nil]];
		
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


- (WEPopoverContainerViewProperties *)sucktasticContainerViewProperties {
	
	WEPopoverContainerViewProperties *props = [[WEPopoverContainerViewProperties alloc] init];
	NSString *bgImageName = nil;
	CGFloat bgMargin = 0.0;
	CGFloat bgCapSize = 0.0;
	CGFloat contentMargin = 4.0;
	
	bgImageName = @"popoverBg.png";
	
	// These constants are determined by the popoverBg.png image file and are image dependent
	bgMargin = 13; // margin width of 13 pixels on all sides popoverBg.png (62 pixels wide - 36 pixel background) / 2 == 26 / 2 == 13 
	bgCapSize = 31; // ImageSize/2  == 62 / 2 == 31 pixels
	
	props.leftBgMargin = bgMargin;
	props.rightBgMargin = bgMargin;
	props.topBgMargin = bgMargin;
	props.bottomBgMargin = bgMargin;
	props.leftBgCapSize = bgCapSize;
	props.topBgCapSize = bgCapSize;
	props.bgImageName = bgImageName;
	props.leftContentMargin = contentMargin;
	props.rightContentMargin = contentMargin - 1; // Need to shift one pixel for border to look correct
	props.topContentMargin = contentMargin; 
	props.bottomContentMargin = contentMargin;
	
	props.arrowMargin = 4.0;
	
	props.upArrowImageName = @"popoverArrowUp.png";
	props.downArrowImageName = @"popoverArrowDown.png";
	props.leftArrowImageName = @"popoverArrowLeft.png";
	props.rightArrowImageName = @"popoverArrowRight.png";
	return props;	
}


- (void)inputPortStripTappedWithRect:(CGRect)inInputPortsRect patchView:(WMPatchView *)inPatchView;
{	
	if (inputPortsPopover) {
		[inputPortsPopover dismissPopoverAnimated:NO];
	}
	WMInputPortsController *content = [[WMInputPortsController alloc] initWithNibName:@"WMInputPortsController" bundle:nil];
	content.ports = inPatchView.patch.inputPorts;

	inputPortsPopover = [[WEPopoverController alloc] initWithContentViewController:content];
	inputPortsPopover.containerViewProperties = [self sucktasticContainerViewProperties];
	
	inputPortsPopover.delegate = (id<WEPopoverControllerDelegate>)self;
	[inputPortsPopover presentPopoverFromRect:[self.view convertRect:inInputPortsRect fromView:inPatchView] inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)showSettingsForPatchView:(WMPatchView *)inPatchView;
{
	if (inPatchView.patch.hasSettings && !patchSettingsPopover) {
		UIViewController<WMPatchSettingsController> *settingsController = [inPatchView.patch settingsController];
		settingsController.editViewController = self;
		
		WMPatchSettingsPresentationStyle settingsPresentationStyle = WMPatchSettingsPresentationStylePopover;
		if ([settingsController respondsToSelector:@selector(settingsPresentationStyle)]) {
			settingsPresentationStyle = settingsController.settingsPresentationStyle;
		}
		
		UINavigationController *wrapper = [[UINavigationController alloc] initWithRootViewController:settingsController];

		if (settingsPresentationStyle == WMPatchSettingsPresentationStylePopover) {
			
			patchSettingsPopover = [[UIPopoverController alloc] initWithContentViewController:wrapper];
			patchSettingsPopover.delegate = (id<UIPopoverControllerDelegate>)self;
			[patchSettingsPopover presentPopoverFromRect:inPatchView.frame inView:inPatchView.superview permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		} else {
			
			[self presentViewController:wrapper animated:YES completion:NULL];
			
		}
	}
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)inPopoverController;
{
	if (inPopoverController == patchSettingsPopover) {
		patchSettingsPopover = nil;
	} else if (inPopoverController == addNodePopover) {
		addNodePopover = nil;
	} else if (inPopoverController == (UIPopoverController *)inputPortsPopover) {
		inputPortsPopover = nil;
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


//////// THE FOLLOWING IS A HUGE HACK FOR POPVIDEO AND YOU SHOULD REMOVE THIS ////////////

- (IBAction)_hackUpload:(UIButton *)sender;
{
	NSString *patchName = document.fileURL.lastPathComponent;
	NSString *zipFileName = [patchName stringByAppendingPathExtension:@"zip"];
	
	//Write contents to temporary location
	NSURL *tempZipFile = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"_temp_bundle.wmbundle.zip"] isDirectory:NO];
	NSURL *tempBundleDirectory = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"_temp_bundle.wmbundle"] isDirectory:YES];
	
	//TODO: write in block to other file
	
	NSError *writeError = NULL;
	NSFileWrapper *contents = [document contentsForType:@"wmbundle" error:NULL];
	BOOL success = [contents writeToURL:tempBundleDirectory options:NSFileWrapperWritingAtomic originalContentsURL:document.fileURL error:&writeError];
	if (success) {
		NSLog(@"Saved to url %@", tempBundleDirectory);
	} else {
		NSLog(@"Couldn't save to url %@", tempBundleDirectory);
	}
	
	DNZipArchive *dnza = [[DNZipArchive alloc] initForWritingWithFileURL:tempZipFile];
	
	[dnza appendDataFromURL:tempBundleDirectory asPath:@"" completion:^(NSError *zipWriteError) {
		if (zipWriteError) {
			NSLog(@"Couldn't write zip because: %@", zipWriteError);
		}
		
		[dnza closeWithCompletion:^(NSError *zipWriteError) {
			if (zipWriteError) {
				NSLog(@"Couldn't write zip because: %@", zipWriteError);
			}
			
			//YAY, now upload the file for goodness sake
			ASIS3ObjectRequest *request = [ASIS3ObjectRequest PUTRequestForFile:tempZipFile.path withBucket:@"popvideo-filters" key:zipFileName];
			
			request.completionBlock = ^{
				NSLog(@"Uploaded file!");
			};
			request.failedBlock = ^{
				NSLog(@"Hmm, somehow that didn't upload erorr: %@", request.error);
			};
			request.accessPolicy = ASIS3AccessPolicyPublicRead;
			request.accessKey = @"AKIAJN6MQRSOHDO6ZAMA";
			request.secretAccessKey = @"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";
			
			[request startAsynchronous];
			
		}];
	}];
}


///////////////////////// END HUGE HACK /////////////////////////////////////////////////



@end
