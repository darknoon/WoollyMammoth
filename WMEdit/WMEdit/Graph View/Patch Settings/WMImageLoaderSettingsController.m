//
//  WMImageLoaderSettingsController.m
//  WMEdit
//
//  Created by Andrew Pouliot on 8/1/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMImageLoaderSettingsController.h"
#import "WMEditViewController.h"
#import "WMBundleDocument.h"
#import <AssetsLibrary/AssetsLibrary.h>

@implementation WMImageLoader (WMPatch_SettingsControllerClass)

- (BOOL)hasSettings;
{
	return YES;
}

- (UIViewController<WMPatchSettingsController> *)settingsController;
{
	return [[WMImageLoaderSettingsController alloc] initWithPatch:self];
}

@end


@implementation WMImageLoaderSettingsController {
	UIPopoverController *imagePickerPopover;
}
@synthesize patch;
@synthesize imageView;
@synthesize editViewController;

- (id)initWithPatch:(WMImageLoader *)inPatch;
{
	self = [self initWithNibName:NSStringFromClass([self class]) bundle:nil];
	if (!self) return nil;
	
	patch = inPatch;
	
	return self;
}


- (void)refreshImageFromPatch;
{
	if (patch.imageResource) {
		NSFileWrapper *wrapper = [[self.editViewController.document resourceWrappers] objectForKey:patch.imageResource];
		self.imageView.image = [UIImage imageWithData:[wrapper regularFileContents]];
	} else {
		self.imageView.image = nil;
	}
}


- (void)viewDidLoad;
{
	[self refreshImageFromPatch];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (IBAction)choosePhoto:(id)sender;
{
	UIImagePickerController *controller = [[UIImagePickerController alloc] init];
	controller.delegate = self;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		imagePickerPopover = [[UIPopoverController alloc] initWithContentViewController:controller];
		[imagePickerPopover presentPopoverFromRect:((UIButton *)sender).frame inView:((UIButton *)sender) permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
	} else {
		[self.navigationController presentViewController:controller animated:YES completion:NULL];
	}
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
{
	NSURL *assetURL = [info objectForKey:UIImagePickerControllerReferenceURL];
	
	ALAssetsLibraryAccessFailureBlock fail = ^(NSError *error) {
		[[[UIAlertView alloc] initWithTitle:@"Unable to load image" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil] show];
		[picker dismissViewControllerAnimated:YES completion:NULL];
		[imagePickerPopover dismissPopoverAnimated:YES];
		imagePickerPopover = nil;
	};
	
	ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
	[library assetForURL:assetURL resultBlock:^(ALAsset *asset) {
		
		ALAssetRepresentation *rep = [asset defaultRepresentation];
		if (rep) {
			//Copy this asset into the document
			[self.editViewController.document addResourceNamed:rep.filename fromAssetRepresentation:rep completion:^(NSError *error) {
				if (error) {
					fail(error);
				} else {
					patch.imageResource = rep.filename;
					[self refreshImageFromPatch];
					[picker dismissViewControllerAnimated:YES completion:NULL];
				}
			}];
		} else {
			fail(nil);
		}
	} failureBlock:fail];
	
}

- (void)viewDidUnload {
	[self setImageView:nil];
	[super viewDidUnload];
}
@end
