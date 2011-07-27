//
//  WMCustomPopoverView.h
//  WMEdit
//
//  Created by Andrew Pouliot on 7/26/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WMCustomPopoverView : UIView

@property (nonatomic, retain) UIView *contentView;

@property (nonatomic) UIPopoverArrowDirection arrowDirection;

@property (nonatomic) CGPoint arrowLocation;

- (CGRect)frameForPoint:(CGPoint)inPoint size:(CGSize)desiredSize inRect:(CGRect)inRect;

@end
