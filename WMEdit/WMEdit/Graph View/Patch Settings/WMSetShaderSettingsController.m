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

@implementation WMSetShaderSettingsController
@synthesize textView;
@synthesize patch;
@synthesize editingFragmentShader;

- (id)initWithPatch:(WMSetShader *)inPatch;
{
    self = [self initWithNibName:@"WMSetShaderSettingsController" bundle:nil];
	if (!self) return nil;

    patch = [inPatch retain];
	editingFragmentShader = NO;
	
	return self;
}

- (void)dealloc {
    [patch release];
	[textView release];
    [super dealloc];
}


#pragma mark - View lifecycle

- (IBAction)toggleEditingVertexOrFragmentShader:(UISegmentedControl *)sender;
{
	self.editingFragmentShader = [(UISegmentedControl *)sender selectedSegmentIndex] == 1;
	self.textView.text = editingFragmentShader ? self.patch.fragmentShader : self.patch.vertexShader;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	self.textView.text = editingFragmentShader ? self.patch.fragmentShader : self.patch.vertexShader;
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
	if (editingFragmentShader) {
		self.patch.fragmentShader = self.textView.text;
	} else {
		self.patch.vertexShader = self.textView.text;
	}
}

@end
