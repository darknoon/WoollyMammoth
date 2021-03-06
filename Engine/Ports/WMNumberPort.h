//
//  WMNumberPort.h
//  Particulon
//
//  Created by Andrew Pouliot on 4/19/11.
//  Copyright 2011 Darknoon. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "WMPort.h"

@interface WMNumberPort : WMPort {
}
@property (nonatomic) float value;

//Suggested min/max, not hard limits
@property (nonatomic) float minValue;
@property (nonatomic) float maxValue;

@end
