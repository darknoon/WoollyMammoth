//
//  WMGraphEditView.h
//  WMEdit
//
//  Created by Andrew Pouliot on 7/16/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "WMPatchView.h"

static const CGFloat offsetBetweenDots = 15.f;
static const CGFloat leftOffset = 15.f;
static const CGFloat plugstripHeight = 23.f;

@interface WMGraphEditView : UIView

@property (nonatomic, retain) WMPatch *rootPatch;

- (void)addPatch:(WMPatch *)inPatch;
- (void)removePatch:(WMPatch *)inPatch;

- (WMPatchView *)patchViewForKey:(NSString *)inKey;

- (void)beginDraggingConnectionFromLocation:(CGPoint)inPoint inPatchView:(WMPatchView *)inView;
- (void)continueDraggingConnectionWithLocation:(CGPoint)inPoint inPatchView:(WMPatchView *)inView;
- (void)endDraggingConnectionWithLocation:(CGPoint)inPoint inPatchView:(WMPatchView *)inView;

- (BOOL)patchHit:(CGPoint)pt;


@end
