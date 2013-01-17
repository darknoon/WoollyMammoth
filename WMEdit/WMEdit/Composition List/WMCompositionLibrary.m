//
//  WMCompositionLibrary.m
//  WMEdit
//
//  Created by Andrew Pouliot on 1/16/13.
//  Copyright 2013 Darknoon. All rights reserved.
//

#import "WMCompositionLibrary.h"

NSString *WMCompositionLibraryCompositionsChangedNotification = @"WMCompositionLibraryCompositionsChanged";

@implementation WMCompositionLibrary {
	NSArray *_compositions;
	NSURL *_documentURL;
}

- (id)init;
{
	self = [super init];
	if (!self) return nil;
	
	_compositions = [self compositionsInDocuments];
	
	return self;
}

+ (instancetype)sharedLibrary;
{
	static WMCompositionLibrary *_library;
	if (!_library) {
		_library = [[WMCompositionLibrary alloc] init];
	}
	return _library;
}

- (void)refresh;
{
	BOOL changed = NO;
	NSArray *new = [self compositionsInDocuments];
	for (NSURL *u in new) {
		if (![_compositions containsObject:u]) {
			changed = YES;
			break;
		}
	}
	if (changed) {
		_compositions = new;
		[[NSNotificationCenter defaultCenter] postNotificationName:WMCompositionLibraryCompositionsChangedNotification object:self];
	}
}

- (NSArray *)compositionsInDocuments;
{
	NSMutableArray *mutableCompositions = [[NSMutableArray alloc] init];
	NSString *documentDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
	for (NSString *compositionFileName in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentDirectory error:NULL]) {
		NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:[documentDirectory stringByAppendingPathComponent:compositionFileName]];
		[mutableCompositions addObject:fileURL];
	}
	return [mutableCompositions copy];
}

- (NSURL *)untitledDocumentURL;
{
	NSString *documentDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
	//Check if a document already exists called "untitled document"
	NSString *name = nil;
	NSURL *fileURL = nil;
	int i=0;
	do {
		name = [NSString stringWithFormat:@"Untitled Document %d.wmbundle", ++i];
		fileURL = [[[NSURL alloc] initFileURLWithPath:documentDirectory] URLByAppendingPathComponent:name];
	} while ([_compositions containsObject:fileURL]);
	
	return fileURL;
	
}

@end
