//
//  WMCompositionListViewController.m
//  Particulon
//
//  Created by Andrew Pouliot on 4/24/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMCompositionListViewController.h"

#import "WMViewController.h"

@implementation WMCompositionListViewController

- (void)sharedInit;
{
}

- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
	if (!self) return nil;
	
	[self sharedInit];
	
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
	if (!self) return nil;
	
	[self sharedInit];
	
	return self;
}

- (void)dealloc
{
    [super dealloc];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

	NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
	NSArray *resources = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:resourcePath error:NULL];
	NSMutableArray *compositionsMutable = [NSMutableArray array];
	
	for (NSString *composition in resources) {
		if ([[composition pathExtension] isEqualToString:@"qtz"]) {
			[compositionsMutable addObject:composition];
		}
	}
	compositions = [compositionsMutable copy];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
	
	[compositions release];
	compositions = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
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
    return compositions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
	cell.textLabel.text = [compositions objectAtIndex:indexPath.row];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	WMViewController *viewController = [[[WMViewController alloc] initWithNibName:nil bundle:nil] autorelease];
	
	NSString *composition = [compositions objectAtIndex:indexPath.row];
	NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
	NSURL *url = [NSURL fileURLWithPath:[resourcePath stringByAppendingPathComponent:composition] isDirectory:YES];
	
	[viewController reloadEngineFromURL:url];
	
	[self.navigationController pushViewController:viewController animated:YES];
}

@end
