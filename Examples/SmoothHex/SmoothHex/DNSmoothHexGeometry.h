//
//  DNSmoothHexGeometry.h
//  SmoothHex
//
//  Created by Andrew Pouliot on 1/29/13.
//  Copyright (c) 2013 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WMRenderObject;

//Creates a tiled hexagonal geometry in a given rect
@interface DNSmoothHexGeometry : NSObject

//Rect to fill with the geometry
@property CGRect rect;

@property float r;

- (WMRenderObject *)generate;

@end
