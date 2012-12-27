//
//  WMEditorWindow.m
//  WMEdit
//
//  Created by Andrew Pouliot on 12/26/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import "WMEditorWindow.h"

#import <QuartzCore/QuartzCore.h>

@implementation WMEditorWindow

- (void)awakeFromNib;
{
	[super awakeFromNib];
	
	[self.contentView setWantsLayer:YES];
	
	CALayer *rootLayer = ((NSView *)self.contentView).layer;
	rootLayer.cornerRadius = 3.0;
	rootLayer.masksToBounds = YES;
	rootLayer.backgroundColor = [NSColor colorWithDeviceWhite:0.3 alpha:1].CGColor;
	
	CALayer *stretchableInnerShadowLayer = [[CALayer alloc] init];
	stretchableInnerShadowLayer.contents = [NSImage imageNamed:@"EditorWindowInnerShadow"];
	stretchableInnerShadowLayer.contentsCenter = (CGRect){0.5, 0.5, 0.1, 0.1};
	stretchableInnerShadowLayer.frame = rootLayer.bounds;
	stretchableInnerShadowLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
	[rootLayer addSublayer:stretchableInnerShadowLayer];
	
	
	NSButton *closeButton = [NSWindow standardWindowButton:NSWindowCloseButton forStyleMask:NSClosableWindowMask];
//	[self.contentView addSubview:closeButton];
}

@end
