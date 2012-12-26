//
//  WMBundleDocument.h
//  WMEdit
//
//  Created by Andrew Pouliot on 12/25/12.
//  Copyright (c) 2012 Darknoon. All rights reserved.
//

#import <WMGraph/WMGraph.h>

#import "DNDocument.h"

@class WMComposition;
@interface WMBundleDocument : DNDocument

//If the document is open, you can read this
@property (nonatomic, readonly) WMComposition *composition;

@end
