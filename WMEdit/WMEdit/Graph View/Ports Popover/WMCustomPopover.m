//
//  WMCustomPopover.m
//  WMEdit
//
//  Created by Andrew Pouliot on 7/26/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import "WMCustomPopover.h"

#import "WMCustomPopoverView.h"

@interface WMCustomPopover ()

@end

@implementation WMCustomPopover
@synthesize contentViewController;
@synthesize delegate;

- (id)initWithContentViewController:(UIViewController *)inViewController;
{
	self = [super initWithNibName:nil bundle:nil];
	if (!self) return nil;
	
	contentViewController = [inViewController retain];
	[self addChildViewController:contentViewController];
	
	return self;
}

- (UIViewController *)nextAncestorViewController:(UIView *)inView;
{
	while (inView) {
		if ([inView.nextResponder isKindOfClass:[UIViewController class]]) {
			return (UIViewController *)inView.nextResponder;
		}
		inView = inView.superview;
	}
	return nil;
}

- (void)presentPopoverFromRect:(CGRect)rect inView:(UIView *)view permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated;
{
	UIViewController *parent = [self nextAncestorViewController:view];
	[parent addChildViewController:self];
	
	WMCustomPopoverView *popoverView = (WMCustomPopoverView *)self.view;

	CGPoint fromPointInParentBounds = (CGPoint){CGRectGetMidX(rect), CGRectGetMidY(rect)};
	
	self.view.frame = [popoverView frameForPoint:fromPointInParentBounds size:(CGSize){.width = 373.f, .height = 400.f} inRect:[view convertRect:view.window.bounds fromView:view.window]];

	[view addSubview:self.view];
	
	popoverView.arrowLocation = [popoverView convertPoint:rect.origin fromView:view];
	[popoverView setNeedsLayout];
}

- (void)dismissPopoverAnimated:(BOOL)animated;
{
	[self removeFromParentViewController];
	[self.view removeFromSuperview];
}

- (void)_dismiss;
{
	BOOL should = !delegate || ![delegate respondsToSelector:@selector(customPopoverControllerShouldDismissPopover:)] || [delegate customPopoverControllerShouldDismissPopover:self];
	if (should) {
		[self dismissPopoverAnimated:NO];
		[delegate customPopoverControllerDidDismissPopover:self];
	}
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
{
	//Are any touches outside?
	for (UITouch *touch in touches) {
		if (!CGRectContainsPoint(self.view.bounds, [touch locationInView:self.view])) {
			[self _dismiss];
			return;
		}
	}
	[super touchesBegan:touches withEvent:event];
}


#pragma mark - View lifecycle

- (void)loadView;
{
	WMCustomPopoverView *customPopoverView = [[WMCustomPopoverView alloc] initWithFrame:CGRectZero];
	customPopoverView.contentView = contentViewController.view;
	self.view = customPopoverView;
	[customPopoverView release];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

@end
