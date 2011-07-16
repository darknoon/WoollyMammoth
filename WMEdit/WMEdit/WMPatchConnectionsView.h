//
//  WMPatchConnectionsView.h
//  WMEdit
//
//  Created by Andrew Pouliot on 7/16/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WMConnection;

#import "WMPatchView.h"

@interface WMPatchConnectionsView : UIView

@property (nonatomic, retain) WMPatch *rootPatch;

- (void)reloadAllConnections;

- (void)addDraggingConnectionFromPatchView:(WMPatchView *)inPatch;
- (void)setConnectionEndpoint:(CGPoint)inPoint fromPatchView:(WMPatchView *)inPatch;
- (void)removeDraggingConnectionFromPatchView:(WMPatchView *)inPatch;

@end
