//
//  WMAddNodeViewController.m
//  WMEdit
//
//  Created by Andrew Pouliot on 12/26/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import "WMAddNodeViewController.h"

#import <WMGraph/WMGraph.h>

@interface WMAddNodeViewController ()

@property (nonatomic, copy) NSString *filterText;
@property (nonatomic, weak) IBOutlet NSTableView *tableView;

@end

@implementation WMAddNodeViewController {
	NSArray *_allNodesList;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (!self) return nil;
	
	_allNodesList = [WMPatch patchClasses];
    
    return self;
}

- (void)dealloc
{
	//rdar: crashes without this
	self.tableView.delegate = nil;
	self.tableView.dataSource = nil;
}

- (void)awakeFromNib;
{
	[super awakeFromNib];
	[self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
}

- (NSString *)filterTextForComparison;
{
	return [[self.filterText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
}

- (NSArray *)filteredNodeList;
{
	if ([self filterTextForComparison].length == 0) return _allNodesList;
	NSPredicate *containsTextPredicate = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
		NSString *patchName = [(Class)evaluatedObject humanReadableTitle];
		BOOL titleContains = [[patchName lowercaseString] rangeOfString:[self filterTextForComparison]].location != NSNotFound;
		BOOL classNameContains = [[NSStringFromClass(evaluatedObject) lowercaseString] rangeOfString:[self filterTextForComparison]].location != NSNotFound;
		return titleContains || classNameContains;
	}];
	return [[_allNodesList copy] filteredArrayUsingPredicate:containsTextPredicate];
}

#pragma mark - NSTableViewDataSource (view-based)

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView;
{
	return [self filteredNodeList].count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row;
{
	return [[self filteredNodeList] objectAtIndex:row];
}

#pragma mark - NSTableViewDelegate

- (void)doubleClickCell;
{
	
}


#pragma mark - NSTextFieldDelegate

- (void)insertNewline:(id)sender;
{
	if ([self filteredNodeList].count > 0) {
		[self.delegate addNodeViewController:self finishWithNodeNamed:[self filteredNodeList][0]];
	} else {
		[self.delegate addNodeCancel:self];
	}
}

static BOOL NSSelectorIsEqual(SEL a, SEL b) {
	return strcmp((const char *)a, (const char *)b) == 0;
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector;
{
	if (NSSelectorIsEqual(commandSelector, @selector(moveUp:))) {
		//Get current selection
		[self moveUp:textView];
		return YES;
	} else if (NSSelectorIsEqual(commandSelector, @selector(moveDown:))) {
		[self moveDown:textView];
		return YES;
	} else if (NSSelectorIsEqual(commandSelector, @selector(insertNewline:))) {
		[self insertNewline:textView];
		return YES;
	} else {
		return NO;
	}
}

- (void)moveUp:(id)sender;
{
	NSUInteger selected = [[self.tableView selectedRowIndexes] firstIndex];
	if (selected > 0) {
		[self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selected - 1] byExtendingSelection:NO];
	}
}

- (void)moveDown:(id)sender;
{
	NSUInteger selected = [[self.tableView selectedRowIndexes] firstIndex];
	NSUInteger count = [self filteredNodeList].count;
	if (count > 0 && selected < count - 1) {
		[self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selected + 1] byExtendingSelection:NO];
	}

}

- (void)controlTextDidChange:(NSNotification *)obj;
{
	self.filterText = self.searchField.stringValue;
	[self.tableView reloadData];
	[self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
}

@end
