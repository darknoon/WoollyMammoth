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
@property (nonatomic, weak) IBOutlet WMView *previewView;
@property (nonatomic, weak) IBOutlet NSScrollView *graphScrollView;

@end

@implementation WMBundleDocument {
	WMComposition *_composition;
	WMViewController *_previewController;
}

- (id)init
{
    self = [super init];
	if (!self) return nil;
	
	_composition = [[WMComposition alloc] init];
	
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
	
	WMViewController *vc = [[WMViewController alloc] initWithComposition:_composition];
	WMView *view = [[WMView alloc] initWithFrame:((NSView *)aController.window.contentView).bounds];
	[(NSView *)aController.window.contentView addSubview:view positioned:NSWindowBelow relativeTo:self.graphScrollView];
	view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	vc.view = view;
	_previewController = vc;
	self.previewView = view;
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper ofType:(NSString *)typeName error:(NSError **)outError;
{
	WMComposition *c = [[WMComposition alloc] initWithFileWrapper:fileWrapper error:outError];
	if (c) {
		_composition = c;
		_previewController.document = c;
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
