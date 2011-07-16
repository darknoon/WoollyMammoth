//
//  WMPatchConnectionsView.h
//  WMEdit
//
//  Created by Andrew Pouliot on 7/16/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WMConnection;
@class WMPort;
@class WMGraphEditView;

#import "WMPatchView.h"

@interface WMPatchConnectionsView : UIView

@property (nonatomic, assign) WMGraphEditView *graphView;
@property (nonatomic, retain) WMPatch *rootPatch;

- (void)reloadAllConnections;

- (void)addDraggingConnectionFromPatchView:(WMPatchView *)inPatch port:(WMPort *)inPort;
- (void)setConnectionEndpoint:(CGPoint)inPoint fromPatchView:(WMPatchView *)inPatch;
- (void)removeDraggingConnectionFromPatchView:(WMPatchView *)inPatch;

@end
