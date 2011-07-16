//
//  WMPatchView.h
//  WMEdit
//
//  Created by Andrew Pouliot on 7/15/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface WMPatchView : UIView

@property BOOL dragging;
@property BOOL draggable;


@property (nonatomic, retain) NSString *name;

@end
