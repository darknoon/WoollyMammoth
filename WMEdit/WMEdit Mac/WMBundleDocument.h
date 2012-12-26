//
//  WMEDocument.h
//  WMEdit Mac
//
//  Created by Andrew Pouliot on 12/24/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <WMGraph/WMGraph.h>

@interface WMBundleDocument : NSDocument

@property (nonatomic, readonly) WMComposition *composition;

@end
