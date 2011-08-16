//
//  WMPatchView.h
//  WMEdit
//
//  Created by Andrew Pouliot on 7/15/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WMGraphEditView;
@class WMPatch;
@class WMPort;

@interface WMPatchView : UIView

@property (nonatomic, weak) WMGraphEditView *graphView;

@property BOOL dragging;
@property BOOL draggable;

@property (nonatomic, readonly) WMPatch *patch;

- (id)initWithPatch:(WMPatch *)inPatch;

- (WMPort *)inputPortAtPoint:(CGPoint)inPoint inView:(UIView *)inView;
- (WMPort *)outputPortAtPoint:(CGPoint)inPoint inView:(UIView *)inView;

- (CGPoint)pointForInputPort:(WMPort *)inputPort;
- (CGPoint)pointForOutputPort:(WMPort *)outputPort;

@end
