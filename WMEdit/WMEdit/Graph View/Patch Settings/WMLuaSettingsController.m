//
//  WMLuaSettingsController.m
//  WMEdit
//
//  Created by Andrew Pouliot on 10/13/11.
//  Copyright (c) 2011 Darknoon. All rights reserved.
//

#import "WMLuaSettingsController.h"
#import "WMEditViewController.h"

@implementation WMLua (WMPatch_SettingsControllerClass)

- (BOOL)hasSettings;
{
	return YES;
}

- (UIViewController<WMPatchSettingsController> *)settingsController;
{
	return [[WMLuaSettingsController alloc] initWithPatch:self];
}

@end


@implementation WMLuaSettingsController {
	int segmentIndex;
}
@synthesize segmentedControl;
@synthesize patch;
@synthesize textView;
@synthesize editViewController;

- (id)initWithPatch:(WMLua *)inPatch;
{
	self = [super init];
	if (!self) return nil;
	
	patch = inPatch;
	
	return self;
}

- (WMPatchSettingsPresentationStyle)settingsPresentationStyle;
{
	return WMPatchSettingsPresentationStyleFullScreen;
}

#pragma mark - View lifecycle

- (void)updateText;
{
	if (segmentIndex == 0) {
		self.textView.text = patch.programText;
		self.textView.editable = YES;
	} else {
		self.textView.text = patch.consoleOutput;
		self.textView.editable = NO;
	}
}

- (IBAction)switchView:(UISegmentedControl *)sender;
{
	segmentIndex = sender.selectedSegmentIndex;
	[self updateText];
}

- (void)close:(id)sender;
{
	[self.editViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.navigationItem.titleView = segmentedControl;
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(close:)];
	
	[self updateText];
}

- (void)viewDidUnload
{
	[self setSegmentedControl:nil];
	[self setTextView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)textViewDidChange:(UITextView *)inTextView;
{
	[editViewController modifyNodeGraphWithBlock:^(WMPatch *rootPatch) {
		if (segmentIndex == 0) {
			self.patch.programText = self.textView.text;
		}
	}];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

@end
