//
//  WMGraphEditView.h
//  WMEdit
//
//  Created by Andrew Pouliot on 7/16/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "WMPatchView.h"

@interface WMGraphEditView : UIView

@property (nonatomic, retain) WMPatch *rootPatch;

- (void)addPatch:(WMPatch *)inPatch;

- (void)beginDraggingConnectionFromLocation:(CGPoint)inPoint inPatchView:(WMPatchView *)inView;
- (void)continueDraggingConnectionWithLocation:(CGPoint)inPoint inPatchView:(WMPatchView *)inView;
- (void)endDraggingConnectionWithLocation:(CGPoint)inPoint inPatchView:(WMPatchView *)inView;

@end
