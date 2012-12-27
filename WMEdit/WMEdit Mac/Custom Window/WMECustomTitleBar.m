//
//  WMECustomTitleBar.m
//  WMEdit
//
//  Created by Andrew Pouliot on 12/26/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import "WMECustomTitleBar.h"

@implementation WMECustomTitleBar

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
	if (!self) return nil;
    
	NSTextField *textField = [[NSTextField alloc] initWithFrame:(NSRect)self.bounds];
	
	[self addSubview:textField];
	
    return self;
}

@end
