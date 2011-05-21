//
//  WMImagePort.h
//  Particulon
//
//  Created by Andrew Pouliot on 4/19/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMPort.h"

@class WMTexture2D;

@interface WMImagePort : WMPort {
    
}
@property (nonatomic, retain) WMTexture2D *image;

@end
