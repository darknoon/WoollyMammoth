//
//  WMCompositionLibraryViewController.m
//  WMEdit
//
//  Created by Androidicus Maximus on 7/17/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMCompositionLibraryViewController.h"
#import "WMCompositionLibrary.h"

#import "WMEditViewController.h"

@implementation WMCompositionLibraryViewController

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (NSArray *)compositionsAsPaths {
    return [[[WMCompositionLibrary compositionLibrary] compositions] valueForKey:@"path"];
}


- (void)compositionsChanged:(NSNotification *)note {
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(compositionsChanged:) name:CompositionsChangedNotification object:nil];
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
	[self.tableView reloadData];
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self compositionsAsPaths] count] + 1;
}

- (UITableViewCell *)tableView:(UITableView *)inTableView cellForRowAtIndexPath:(NSIndexPath *)inIndexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [inTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
    BOOL notNewCompostion = inIndexPath.row < [self compositionsAsPaths].count;
    
    NSString *path =  notNewCompostion ? (NSString *)[[self compositionsAsPaths] objectAtIndex:inIndexPath.row]: nil;
    UIImage *image = path ? [[WMCompositionLibrary compositionLibrary] imageForCompositionPath:[NSURL fileURLWithPath:path]] : nil;
    
    cell.textLabel.text = notNewCompostion ? [[path lastPathComponent] stringByDeletingPathExtension] : NSLocalizedString(@"New Composition", nil);
    cell.imageView.image = image;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)inIndexPath
{
	WMPatch *p = nil;
	NSURL *fileURL = nil;
	if (inIndexPath.row < [self compositionsAsPaths].count) {
		fileURL = [[[WMCompositionLibrary compositionLibrary] compositions] objectAtIndex:inIndexPath.row];
		p = [[WMCompositionLibrary compositionLibrary] compositionWithURL:fileURL];
	}
	WMEditViewController *e = [[[WMEditViewController alloc] initWithPatch:p fileURL:fileURL] autorelease];
	
	return [self.navigationController pushViewController:e animated:YES];
}

@end
