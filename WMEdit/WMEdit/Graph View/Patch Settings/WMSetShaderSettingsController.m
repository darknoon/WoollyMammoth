//
//  WMSetShaderSettingsController.m
//  WMEdit
//
//  Created by Andrew Pouliot on 7/27/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMSetShaderSettingsController.h"

#import "WMPatch+SettingsControllerClass.h"
#import "WMEditViewController.h"

#import "NSObject_KVOBlockNotificationExtensions.h"

#import <WMGraph/WMGraph.h>
#import <WMGraph/DNKVC.h>

@implementation WMSetShader (WMPatch_SettingsControllerClass)

- (BOOL)hasSettings;
{
	return YES;
}

- (UIViewController<WMPatchSettingsController> *)settingsController;
{
	return [[WMSetShaderSettingsController alloc] initWithPatch:self];
}

@end

@interface WMSetShaderSettingsController ()
@property (nonatomic) int segmentIndex;
- (void)updateErrorLog;
@end

@implementation WMSetShaderSettingsController

@synthesize textView;
@synthesize segmentedControl;
@synthesize patch;
@synthesize segmentIndex;
@synthesize editViewController;

- (id)initWithPatch:(WMSetShader *)inPatch;
{
	self = [self initWithNibName:NSStringFromClass([self class]) bundle:nil];
	if (!self) return nil;

    patch = inPatch;
	__weak WMSetShaderSettingsController *weakSelf = self;
	[patch addObserver:self handler:^(NSString *keyPath, id object, NSDictionary *change, id identifier) {
		//Update our 
		[weakSelf updateErrorLog];
	} forKeyPath:KVC(patch, shaderCompileLog) options:0 identifier:nil];
	
	return self;
}

- (void)dealloc;
{
	[patch removeObserver:self forKeyPath:KVC(patch, shaderCompileLog) identifier:nil];
}

- (WMPatchSettingsPresentationStyle)settingsPresentationStyle;
{
	return WMPatchSettingsPresentationStyleFullScreen;
}

#pragma mark - View lifecycle

- (void)updateErrorLog;
{	
	NSString *summary = patch.shaderCompileLog.length > 0 ? @"Error" : @"Success";
	[self.segmentedControl setTitle:summary forSegmentAtIndex:2];
}

- (void)updateText;
{
	if (segmentIndex == 0) {
		self.textView.text = patch.vertexShader;
		self.textView.editable = YES;
	} else if (segmentIndex == 1) {
		self.textView.text = patch.fragmentShader;
		self.textView.editable = YES;
	} else {
		[self updateErrorLog];
		self.textView.text = patch.shaderCompileLog.length > 0 ? patch.shaderCompileLog : @"Success";
		self.textView.editable = NO;
	}
}

- (void)close:(id)sender;
{
	[self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)toggleEditingVertexOrFragmentShader:(UISegmentedControl *)sender;
{
	self.segmentIndex = [(UISegmentedControl *)sender selectedSegmentIndex];
	[self updateText];
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
    [super viewDidUnload];
	[self setTextView:nil];
}

- (CGSize)contentSizeForViewInPopover;
{
	return (CGSize){.width = 400, .height = 400};
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation;
{
	return YES;
}

#pragma mark - UITextViewDelegate


- (void)textViewDidChange:(UITextView *)inTextView;
{
	if (segmentIndex == 0) {
		self.patch.vertexShader = self.textView.text;
	} else if (segmentIndex == 1) {
		self.patch.fragmentShader = self.textView.text;
	}
	//Ask the shader to compile if possible
	[patch compileShaderIfNecessary];
	[editViewController markDocumentDirty];
}

@end
