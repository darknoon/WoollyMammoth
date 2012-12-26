//
//  WMCompositionLibraryViewController.m
//  WMEdit
//
//  Created by Androidicus Maximus on 7/17/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMCompositionLibraryViewController.h"
#import "WMCompositionLibrary.h"

#import <WMGraph/WMComposition.h>

#import "WMEditViewController.h"
#import "WMBundleDocument.h"
#import "NSObject_KVOBlockNotificationExtensions.h"
#import <WMGraph/DNKVC.h>

@implementation WMCompositionLibraryViewController {
	NSMutableArray *compositions;
}



#pragma mark - View lifecycle

- (NSIndexPath *)indexPathForCompositionIndex:(NSUInteger)inIndex;
{
	return [NSIndexPath indexPathForRow:inIndex inSection:0];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
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
	compositions = [[[WMCompositionLibrary compositionLibrary] compositions] mutableCopy];
	
	__weak WMCompositionLibraryViewController *weakSelf = self;
	[[WMCompositionLibrary compositionLibrary] addObserver:self handler:^(NSString *keyPath, id object, NSDictionary *change, id identifier) {
		WMCompositionLibraryViewController *self = weakSelf;
		
		NSIndexSet *indexes = [change objectForKey:NSKeyValueChangeIndexesKey];
		if (indexes) {
			NSMutableArray *indexPathArray = [[NSMutableArray alloc] initWithCapacity:indexes.count];
			[indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
				[indexPathArray addObject:[NSIndexPath indexPathForRow:idx inSection:0]];
			}];
			
			
			[self.tableView beginUpdates];
			//Either insert or remove table rows corresponding to the type of change that occurred
			NSNumber *kind = [change objectForKey:NSKeyValueChangeKindKey];
			if ([kind unsignedIntegerValue] == NSKeyValueChangeInsertion) {
				[self->compositions insertObjects:[change objectForKey:NSKeyValueChangeNewKey] atIndexes:indexes];
				[self.tableView insertRowsAtIndexPaths:indexPathArray withRowAnimation:UITableViewRowAnimationFade];
			} else if ([kind unsignedIntegerValue] == NSKeyValueChangeRemoval) {
				[self->compositions removeObjectsAtIndexes:indexes];
				[self.tableView deleteRowsAtIndexPaths:indexPathArray withRowAnimation:UITableViewRowAnimationFade];
			}
			[self.tableView endUpdates];
		} else {
			self->compositions = [[[WMCompositionLibrary compositionLibrary] compositions] mutableCopy];
			[self.tableView reloadData];
		}
	} forKeyPath:KVC([WMCompositionLibrary compositionLibrary], compositions) options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld identifier:nil];
    
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
	compositions = nil;
	[[WMCompositionLibrary compositionLibrary] removeObserver:self forKeyPath:KVC([WMCompositionLibrary compositionLibrary], compositions) identifier:nil];
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
    return compositions.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)inTableView cellForRowAtIndexPath:(NSIndexPath *)inIndexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [inTableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    BOOL notNewCompostion = inIndexPath.row < compositions.count;
    
    NSURL *url = notNewCompostion ? [compositions objectAtIndex:inIndexPath.row]: nil;
    UIImage *image = url ? [[WMCompositionLibrary compositionLibrary] imageForCompositionPath:url] : nil;
    
    cell.textLabel.text = notNewCompostion ? [[url lastPathComponent] stringByDeletingPathExtension] : NSLocalizedString(@"New Composition", nil);
    cell.imageView.image = image;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)inIndexPath
{
	NSURL *fileURL = nil;
	WMBundleDocument *document = nil;
	if (inIndexPath.row < compositions.count) {
		fileURL = [compositions objectAtIndex:inIndexPath.row];
		document = [[WMBundleDocument alloc] initWithFileURL:fileURL];
		
		NSLog(@"opening document %@", document);
		[document openWithCompletionHandler:^(BOOL success) {
			if (success) {
				NSLog(@"-openWithCompletionHandler: handler called.");
				WMEditViewController *e = [[WMEditViewController alloc] initWithDocument:document];			
				[self.navigationController pushViewController:e animated:YES];
			} else {
				NSLog(@"error reading document.");
			}
		}];


	} else {
		fileURL = [[WMCompositionLibrary compositionLibrary] URLForResourceShortName:@"Untitled Document"];
		document = [[WMBundleDocument alloc] initWithFileURL:fileURL];
		//Write document to the url
		NSLog(@"will make new document at url: %@", fileURL);
		[document saveToURL:fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
			NSLog(@"saved new document to url: %@", fileURL);
			
			NSLog(@"opening document %@", document);
			[document openWithCompletionHandler:^(BOOL success) {
				if (success) {
					NSLog(@"-openWithCompletionHandler: handler called.");
					WMEditViewController *e = [[WMEditViewController alloc] initWithDocument:document];			
					[self.navigationController pushViewController:e animated:YES];
				} else {
					NSLog(@"error reading document.");
				}
			}];

		}];
	}
}

@end
