//
//  WMPatchListTableViewController.h
//  WMEdit
//
//  Created by Andrew Pouliot on 7/16/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol WMPatchListTableViewControllerDelegate;

@interface WMPatchListTableViewController : UITableViewController

@property (nonatomic, assign) id<WMPatchListTableViewControllerDelegate> delegate;
@property (nonatomic, assign) NSArray *patchList;
@property (nonatomic, assign) NSString *category;
@end


@protocol WMPatchListTableViewControllerDelegate <NSObject>

- (id)initWithPatchesAndCategory:(NSArray *)array category:(NSString*)categoryIn;

- (void)patchList:(WMPatchListTableViewController *)inPatchList selectedPatchClassName:(NSString *)inClassName;

@end