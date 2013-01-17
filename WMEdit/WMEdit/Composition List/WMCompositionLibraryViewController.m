//
//  WMCompositionLibraryViewController.m
//  WMEdit
//
//  Created by Andrew Pouliot on 1/16/13.
//  Copyright 2013 Darknoon. All rights reserved.
//

#import "WMCompositionLibraryViewController.h"
#import "WMCompositionLibrary.h"

#import <WMGraph/WMComposition.h>

#import "WMEditViewController.h"
#import "WMBundleDocument.h"
#import "NSObject_KVOBlockNotificationExtensions.h"
#import <WMGraph/DNKVC.h>

static NSString *ident = @"Identifier";

@implementation WMCompositionLibraryViewController {
	WMCompositionLibrary *_library;
}

- (void)viewDidLoad;
{
	_library = [WMCompositionLibrary sharedLibrary];
	[self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:ident];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(compositionsChanged:) name:WMCompositionLibraryCompositionsChangedNotification object:_library];
	[super viewDidLoad];
}

- (void)compositionsChanged:(NSNotification *)note;
{
	[self.tableView reloadData];
}

#pragma mark - Table view delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;
{
	return _library.compositions.count + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ident];
	
	if (indexPath.row < _library.compositions.count) {
		NSString *path = _library.compositions[indexPath.row];
		cell.textLabel.text = [[path lastPathComponent] stringByDeletingPathExtension];
	} else {
		cell.textLabel.text = @"+ New Composition";
	}
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)inIndexPath
{
	NSURL *fileURL = nil;
	WMBundleDocument *document = nil;
	if (inIndexPath.row < _library.compositions.count) {
		fileURL = [_library.compositions objectAtIndex:inIndexPath.row];
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
		fileURL = [_library untitledDocumentURL];
		document = [[WMBundleDocument alloc] initWithFileURL:fileURL];
		//Write document to the url
		NSLog(@"will make new document at url: %@", fileURL);
		[document saveToURL:fileURL forSaveOperation:UIDocumentSaveForCreating completionHandler:^(BOOL success) {
			NSLog(@"saved new document to url: %@", fileURL);
			[[WMCompositionLibrary sharedLibrary] refresh];
			
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
