//
//  WMCustomPopover.h
//  WMEdit
//
//  Created by Andrew Pouliot on 7/26/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol WMCustomPopoverDelegate;

@interface WMCustomPopover : UIViewController

- (id)initWithContentViewController:(UIViewController *)inViewController;
@property (nonatomic, readonly) UIViewController *contentViewController;

@property (nonatomic, assign) id<WMCustomPopoverDelegate> delegate;

- (void)presentPopoverFromRect:(CGRect)rect inView:(UIView *)view permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated;
- (void)dismissPopoverAnimated:(BOOL)animated;

@end

@protocol WMCustomPopoverDelegate <NSObject>

/* Called on the delegate when the popover controller will dismiss the popover. Return NO to prevent the dismissal of the view.
 */
- (BOOL)customPopoverControllerShouldDismissPopover:(WMCustomPopover *)inPopoverController;

/* Called on the delegate when the user has taken action to dismiss the popover. This is not called when -dismissPopoverAnimated: is called directly.
 */
- (void)customPopoverControllerDidDismissPopover:(WMCustomPopover *)inPopoverController;

@end