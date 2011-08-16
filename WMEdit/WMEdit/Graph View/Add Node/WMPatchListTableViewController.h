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

- (id)initWithPatchesAndCategory:(NSArray *)array category:(NSString*)categoryIn;

@property (nonatomic, unsafe_unretained) id<WMPatchListTableViewControllerDelegate> delegate;
@property (nonatomic, copy) NSArray *patchList;
@property (nonatomic, copy) NSString *category;
@end


@protocol WMPatchListTableViewControllerDelegate <NSObject>

- (void)patchList:(WMPatchListTableViewController *)inPatchList selectedPatchClassName:(NSString *)inClassName;

@end