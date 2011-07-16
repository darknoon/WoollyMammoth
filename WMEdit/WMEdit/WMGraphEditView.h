//
//  WMGraphEditView.h
//  WMEdit
//
//  Created by Andrew Pouliot on 7/16/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "WMPatch.h"

@interface WMGraphEditView : UIView

@property (nonatomic, retain) WMPatch *rootPatch;

- (void)addPatch:(WMPatch *)inPatch;

@end
