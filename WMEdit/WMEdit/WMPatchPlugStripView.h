//
//  WMPatchPlugStripView.h
//  WMEdit
//
//  Created by Andrew Pouliot on 7/15/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface WMPatchPlugStripView : UIView

@property (nonatomic) NSUInteger inputCount;

- (NSUInteger)portIndexAtPoint:(CGPoint)inPoint;
- (CGPoint)pointForPortIndex:(NSUInteger)inIndex;

@end
