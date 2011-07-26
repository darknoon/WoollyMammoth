//
//  WMColorPort.h
//  Particulon
//
//  Created by Andrew Pouliot on 4/19/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMPort.h"

#import "WMRenderCommon.h"

#import "WMVectorPort.h"

//This port just indicates that its contents represent a color
@interface WMColorPort : WMVector4Port {}

@end
