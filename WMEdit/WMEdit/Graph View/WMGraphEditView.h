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
static const CGFloat plugstripHeight = 22.f;

@class WMEditViewController;

#if TARGET_OS_IPHONE
@interface WMGraphEditView : UIScrollView
#elif TARGET_OS_MAC
@interface WMGraphEditView : NSScrollView
#endif

@property (nonatomic, weak) WMEditViewController *viewController;

@property (nonatomic, strong) WMPatch *rootPatch;

- (void)addPatch:(WMPatch *)inPatch;
- (void)removePatch:(WMPatch *)inPatch;

- (WMPatchView *)patchViewForKey:(NSString *)inKey;


- (CGPoint)editorPositionForPoint:(CGPoint)inPoint;
- (CGPoint)pointForEditorPosition:(CGPoint)inEditorPosition;

- (void)beginDraggingConnectionFromLocation:(CGPoint)inPoint inPatchView:(WMPatchView *)inView;
- (void)continueDraggingConnectionWithLocation:(CGPoint)inPoint inPatchView:(WMPatchView *)inView;
- (void)endDraggingConnectionWithLocation:(CGPoint)inPoint inPatchView:(WMPatchView *)inView;

- (void)inputPortStripTappedWithRect:(CGRect)inInputPortsRect patchView:(WMPatchView *)inPatchView;

- (void)showSettingsForPatchView:(WMPatchView *)inPatchView;

- (BOOL)patchHit:(CGPoint)pt;

@end
