//
//  WMPatchListTableViewController.m
//  WMEdit
//
//  Created by Andrew Pouliot on 7/16/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMPatchListTableViewController.h"

#import "WMPatch.h"

@implementation WMPatchListTableViewController

@synthesize delegate, patchList, category;

#define kCellHeightPatches  45.0

- (id)initWithPatchesAndCategory:(NSArray *)array category:(NSString*)categoryIn;
{
    self = [super initWithStyle:UITableViewStylePlain];
    patchList = [[NSArray alloc] initWithArray:array];
    category = categoryIn;
    self.title = NSLocalizedString(categoryIn, nil);
    self.contentSizeForViewInPopover = CGSizeMake(320.0, patchList.count * kCellHeightPatches);

    return self;
}

- (CGSize)contentSizeForViewInPopover {
    return CGSizeMake(320.0, patchList.count * kCellHeightPatches);
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

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return patchList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    NSString *className = [patchList objectAtIndex:indexPath.row];
    NSString *pretty = [NSClassFromString(className) humanReadableTitle];
	cell.textLabel.text = pretty ? pretty : className;
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* name = [patchList objectAtIndex:indexPath.row];
    NSString* className = [[WMPatchCategories sharedInstance] classFromCategoryAndName:category name:name];
	[delegate patchList:self selectedPatchClassName:className];
}

@end
