//
//  WMImageLoaderSettingsController.m
//  WMEdit
//
//  Created by Andrew Pouliot on 8/1/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMImageLoaderSettingsController.h"

@implementation WMImageLoader (WMPatch_SettingsControllerClass)

- (BOOL)hasSettings;
{
	return YES;
}

- (UIViewController<WMPatchSettingsController> *)settingsController;
{
	return [[[WMImageLoaderSettingsController alloc] initWithPatch:self] autorelease];
}

@end


@implementation WMImageLoaderSettingsController
@synthesize patch;
@synthesize imageView;

- (id)initWithPatch:(WMImageLoader *)inPatch;
{
	self = [self initWithNibName:NSStringFromClass([self class]) bundle:nil];
	if (!self) return nil;
	
	patch = [inPatch retain];
	
	return self;
}

- (void)dealloc;
{
    [patch release];
	
	[imageView release];
    [super dealloc];
}

- (void)viewDidLoad;
{
	imageView.image = [UIImage imageWithData:patch.imageData];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (IBAction)choosePhoto:(id)sender;
{
	UIImagePickerController *controller = [[[UIImagePickerController alloc] init] autorelease];
	controller.delegate = self;
	[self.navigationController presentViewController:controller animated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
{
	UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
	UIImage *editedImage = [info objectForKey:UIImagePickerControllerEditedImage];
	image = editedImage ? editedImage : image;
	patch.imageData = UIImagePNGRepresentation(image);
	imageView.image = image;
	
	[picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)viewDidUnload {
	[self setImageView:nil];
	[super viewDidUnload];
}
@end
