//
//  WMInputPortCell.h
//  WMEdit
//
//  Created by Andrew Pouliot on 7/26/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <WMGraph/WMGraph.h>

@interface WMInputPortCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *nameLabel;

@property (nonatomic, strong) IBOutlet WMPort *port;

@end
