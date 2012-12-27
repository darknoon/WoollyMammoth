//
//  WMEDocument.m
//  WMEdit Mac
//
//  Created by Andrew Pouliot on 12/24/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import "WMBundleDocument.h"

@interface WMBundleDocument ()

@property (nonatomic, weak) IBOutlet NSView *titleBarContainer;

@end

@implementation WMBundleDocument {
	WMComposition *_composition;
}

- (id)init
{
    self = [super init];
	if (!self) return nil;
	
    return self;
}

- (NSString *)windowNibName
{
	return NSStringFromClass(self.class);
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
	[super windowControllerDidLoadNib:aController];
	[aController.window setCollectionBehavior:NSWindowCollectionBehaviorFullScreenPrimary];
	// Add any code here that needs to be executed once the windowController has loaded the document's window.
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper ofType:(NSString *)typeName error:(NSError **)outError;
{
	WMComposition *c = [[WMComposition alloc] init];
	if (c) {
		_composition = c;
		return YES;
	} else {
		return NO;
	}
}

- (NSFileWrapper *)fileWrapperOfType:(NSString *)typeName error:(NSError **)outError;
{
	return [_composition fileWrapperRepresentationWithError:outError];
}

@end
