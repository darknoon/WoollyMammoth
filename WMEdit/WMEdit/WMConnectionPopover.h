//
//  WMConnectionPopover.h
//  WMEdit
//
//  Created by Andrew Pouliot on 7/17/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WMConnectionPopover : UIView

@property (nonatomic) NSUInteger connectionIndex;
@property (nonatomic, copy) NSArray *ports;
@property (nonatomic) BOOL canConnect;

- (void)setTargetPoint:(CGPoint)inPoint;

- (void)refresh;

@end
