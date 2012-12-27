//
//  WMAddNodeViewController.h
//  WMEdit
//
//  Created by Andrew Pouliot on 12/26/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol WMAddNodeViewControllerDelegate;


@interface WMAddNodeViewController : NSViewController

@property (nonatomic, weak) IBOutlet id<WMAddNodeViewControllerDelegate> delegate;

@property (nonatomic, weak) IBOutlet NSSearchField *searchField;

@end


@protocol WMAddNodeViewControllerDelegate <NSObject>

- (void)addNodeViewController:(WMAddNodeViewController *)controller finishWithNodeNamed:(NSString *)nodeText;
- (void)addNodeCancel:(WMAddNodeViewController *)controller;

@end