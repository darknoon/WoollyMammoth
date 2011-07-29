//
//  WMSetShaderSettingsController.m
//  WMEdit
//
//  Created by Andrew Pouliot on 7/27/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMSetShaderSettingsController.h"

#import "WMSetShader.h"
#import "WMPatch+SettingsControllerClass.h"

@implementation WMSetShader (WMPatch_SettingsControllerClass)

- (Class)settingsControllerClass;
{
	return [WMSetShaderSettingsController class];
}

@end

@interface WMSetShaderSettingsController ()
@property (nonatomic) int segmentIndex;
@end

@implementation WMSetShaderSettingsController
@synthesize textView;
@synthesize patch;
@synthesize segmentIndex;

- (id)initWithPatch:(WMSetShader *)inPatch;
{
    self = [self initWithNibName:@"WMSetShaderSettingsController" bundle:nil];
	if (!self) return nil;

    patch = [inPatch retain];
	
	return self;
}

- (void)dealloc {
    [patch release];
	[textView release];
    [super dealloc];
}


#pragma mark - View lifecycle

- (void)updateText;
{
	if (segmentIndex == 0) {
		self.textView.text = patch.vertexShader;
		self.textView.editable = YES;
	} else if (segmentIndex == 1) {
		self.textView.text = patch.fragmentShader;
		self.textView.editable = YES;
	} else {
		self.textView.text = patch.shaderCompileLog.length > 0 ? patch.shaderCompileLog : @"Success";
		self.textView.editable = NO;
	}
}

- (IBAction)toggleEditingVertexOrFragmentShader:(UISegmentedControl *)sender;
{
	self.segmentIndex = [(UISegmentedControl *)sender selectedSegmentIndex];
	[self updateText];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
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

#pragma mark - UITextViewDelegate


- (void)textViewDidChange:(UITextView *)inTextView;
{
	if (segmentIndex == 0) {
		self.patch.vertexShader = self.textView.text;
	} else if (segmentIndex == 1) {
		self.patch.fragmentShader = self.textView.text;
	}
}

@end
