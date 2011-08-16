//
//  WMPatchListCategoryTableViewController.h
//  WMEdit
//
//  Created by Michael Deitcher on 7/16/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol WMPatchCategoryListTableViewControllerDelegate;

@interface WMPatchCategoryListTableViewController : UITableViewController 

@property (nonatomic, unsafe_unretained) id<WMPatchCategoryListTableViewControllerDelegate> delegate;

@end
